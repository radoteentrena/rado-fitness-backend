class CoachAlert < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, resolved: 1, dismissed: 2 }
  enum :category, { missed_workout: "missed_workout", low_compliance: "low_compliance", weight_spike: "weight_spike", check_in: "check_in" }

  validates :category, presence: true
  validates :message, presence: true

  scope :pending, -> { where(status: :pending) }
end
