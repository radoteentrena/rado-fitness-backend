class Notification < ApplicationRecord
  belongs_to :conversation

  validates :conversation_id, presence: true
  validates :notification_type, presence: true
  validates :message, presence: true
end
