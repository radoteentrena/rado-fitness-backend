class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  enum :sender_type, { client: "client", coach: "coach", system: "system" }

  after_create_commit :broadcast_unread_badge, if: :client?

  has_one_attached :voice_note

  validates :conversation_id, presence: true
  validates :sender_type, presence: true
  validates :content, presence: true, unless: -> { voice_note.attached? }
  validates :voice_note, file_size: { less_than: 5.megabytes }, allow_nil: true

  scope :not_deleted, -> { where(discarded_at: nil) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :unread_from_clients, -> { where(sender_type: :client, read_at: nil, discarded_at: nil) }

  include Discard::Model

  private

  def broadcast_unread_badge
    broadcast_update_to "admin_nav",
      target: "unread_messages_badge",
      partial: "admin/shared/unread_messages_badge"
  end
end
