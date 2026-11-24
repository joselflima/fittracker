class LiftingSet < ApplicationRecord
  belongs_to :workout
  normalizes :exercise, with: ->(name) { name.squish }
  validates :exercise, presence: true, length: { maximum: 100 }
  validates :weight, numericality: { greater_than_or_equal_to: 0 }
  validates :reps, numericality: { only_integer: true, greater_than: 0 }
end
