class Workout < ApplicationRecord
  belongs_to :user
  has_many :lifting_sets, dependent: :destroy
  validates :kind, inclusion: { in: %w[strength running] }
  validates :started_at, presence: true
  validates :distance_km, :run_duration, numericality: { greater_than: 0 }, if: -> { running? && finished_at? }

  def running?
    kind == "running"
  end

  def paused?
    paused_at.present?
  end

  def timer_started_at
    started_at + paused_duration_ms.fdiv(1000)
  end

  def elapsed_seconds
    [ ((paused_at || finished_at || Time.current) - timer_started_at).round, 0 ].max
  end

  def pause!
    with_lock do
      update!(paused_at: Time.current) unless finished_at? || paused?
    end
  end

  def resume!
    with_lock do
      if paused? && !finished_at?
        record_pause_until(Time.current)
        save!
      end
    end
  end

  def cancel!
    with_lock do
      destroy! unless finished_at?
    end
  end

  def pace_seconds
    (run_duration / distance_km).round if run_duration && distance_km&.positive?
  end

  def finish!(inputs)
    with_lock do
      return if finished_at?
      self.finished_at = Time.current
      record_pause_until(finished_at) if paused?
      if running?
        self.distance_km = inputs[:distance_km]
        manual = inputs.values_at(:run_minutes, :run_seconds).any?(&:present?)
        self.run_duration = manual ? duration_from(inputs) : elapsed_seconds
      elsif lifting_sets.empty?
        errors.add(:base, "Adicione uma série antes de finalizar.")
        raise ActiveRecord::RecordInvalid, self
      end
      save!
    end
  end

  private

  def record_pause_until(time)
    self.paused_duration_ms += [ ((time - paused_at) * 1000).round, 0 ].max
    self.paused_at = nil
  end

  def duration_from(inputs)
    minutes, seconds = inputs.values_at(:run_minutes, :run_seconds).map { |part| Integer(part.presence || 0, exception: false) }
    minutes * 60 + seconds if minutes && minutes >= 0 && seconds&.between?(0, 59)
  end
end
