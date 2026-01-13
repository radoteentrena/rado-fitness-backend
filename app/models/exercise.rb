class Exercise < ApplicationRecord
  has_many :routine_items
  has_many :routines, through: :routine_items

  validates :name, presence: true
end
