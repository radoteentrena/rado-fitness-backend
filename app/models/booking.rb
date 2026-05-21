class Booking < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  validates :scheduled_at, presence: true
  validates :user_id, uniqueness: true
end
