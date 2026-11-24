class Workout < ApplicationRecord
  belongs_to :user
  has_many :lifting_sets, dependent: :destroy
  validates :kind, inclusion: { in: %w[strength running] }
  validates :started_at, presence: true
  validates :distance_km, :run_duration, numericality: { greater_than: 0 }, if: -> { running? && finished_at? }

  def running?
    kind == "running"
  end

  def elapsed_seconds
    ((finished_at || Time.current) - started_at).round.clamp(0, Float::INFINITY)
  end

  def pace_seconds
    (run_duration / distance_km).round if run_duration && distance_km&.positive?
  end

  def finish!(inputs)
    with_lock do
      return if finished_at?
      if running?
        self.distance_km = inputs[:distance_km]
        manual = inputs.values_at(:run_minutes, :run_seconds).any?(&:present?)
        self.run_duration = manual ? duration_from(inputs) : elapsed_seconds
      elsif lifting_sets.empty?
        errors.add(:base, "Adicione uma série antes de finalizar.")
        raise ActiveRecord::RecordInvalid, self
      end
      update!(finished_at: Time.current)
    end
  end

  private

  def duration_from(inputs)
    minutes, seconds = inputs.values_at(:run_minutes, :run_seconds).map { |part| Integer(part.presence || 0, exception: false) }
    minutes * 60 + seconds if minutes && minutes >= 0 && seconds&.between?(0, 59)
  end
end
