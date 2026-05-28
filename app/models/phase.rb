class Phase < ApplicationRecord
  belongs_to :program
  has_many :phase_routines, dependent: :destroy
  has_many :routines, through: :phase_routines
  has_many :user_dietary_plans, dependent: :destroy
  has_many :training_sessions, dependent: :destroy

  validates :name, presence: true
end
