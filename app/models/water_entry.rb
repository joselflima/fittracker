class WaterEntry < ApplicationRecord
  belongs_to :user
  validates :milliliters, numericality: { only_integer: true, greater_than: 0 }
end
