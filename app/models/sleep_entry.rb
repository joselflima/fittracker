class SleepEntry < ApplicationRecord
  belongs_to :user
  validates :day, presence: true
  validates :minutes, numericality: { only_integer: true, in: 0..1440 }
end
