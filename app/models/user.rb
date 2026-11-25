class User < ApplicationRecord
  PROFILE_MEASURES = %i[weight_kg height_cm].freeze
  DECIMAL_NUMBER = /\A[+-]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)\z/

  has_secure_password
  has_many :water_entries, dependent: :destroy
  has_many :sleep_entries, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :lab_results, dependent: :destroy

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :display_name, with: ->(value) { value.strip.presence }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, length: { minimum: 12 }, allow_nil: true
  validate :validate_profile_measures, :validate_birth_date

  def exercise_history
    rows = LiftingSet.joins(:workout)
      .where(workouts: { user_id: id, kind: "strength" }).where.not(workouts: { finished_at: nil })
      .order("workouts.started_at", "lifting_sets.id")
      .pluck(:exercise, "workouts.started_at", :weight)

    rows.group_by { |name, _, _| name.downcase }.values.sort_by { |sets| -sets.size }.map do |sets|
      days = sets.group_by { |_, time, _| time.in_time_zone.to_date }
      [ sets.first.first, days.transform_values { |entries| entries.map(&:last).max } ]
    end
  end

  private

  def validate_profile_measures
    PROFILE_MEASURES.each do |attribute|
      input = read_attribute_before_type_cast(attribute)
      next if input.nil? || (input.is_a?(String) && input.blank?)

      number = public_send(attribute).to_f
      next if number.finite? && number.positive? && (input.is_a?(Numeric) || DECIMAL_NUMBER.match?(input.to_s))

      errors.add(attribute, :invalid_profile_measure)
    end
  end

  def validate_birth_date
    input = birth_date_before_type_cast
    return if input.nil? || (input.is_a?(String) && input.blank?)

    if !birth_date.is_a?(Date) || !birth_date.year.positive? || (input.is_a?(String) && input != birth_date.iso8601)
      errors.add(:birth_date, :invalid_profile_date)
    elsif birth_date > Date.current
      errors.add(:birth_date, :future_profile_date)
    end
  end
end
