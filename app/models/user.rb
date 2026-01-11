class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  include Discard::Model

  enum :status, { lead: 0, active: 1, churned: 2, archived: 3 }, default: :lead
  enum :plan_tier, { basic: 0, medium: 1, high_ticket: 2 }

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true

  # Associations (will be added later as per EPIC 2)
  # has_many :daily_metrics
  # has_one :nutrition_plan
  # has_many :routines
end
