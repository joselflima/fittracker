class LabResult < ApplicationRecord
  belongs_to :user
  normalizes :indicator, :unit, with: ->(text) { text.squish }
  validates :indicator, :unit, presence: true, length: { maximum: 100 }
  validates :value, numericality: true
  validates :measured_on, presence: true, comparison: { less_than_or_equal_to: -> { Date.current } }
end
