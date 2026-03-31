class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :user_id, presence: true, uniqueness: true

  scope :order_by_recent, -> { order(last_message_at: :desc) }
end
