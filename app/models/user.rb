class User < ApplicationRecord
  has_secure_password
  has_many :water_entries, dependent: :destroy
  has_many :sleep_entries, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :lab_results, dependent: :destroy

  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :password, length: { minimum: 12 }, allow_nil: true

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
end
