class Message < ApplicationRecord
  belongs_to :user
  belongs_to :conversation

  enum :sender_type, { client: "client", coach: "coach", system: "system" }

  has_one_attached :voice_note

  validates :conversation_id, presence: true
  validates :sender_type, presence: true
  validates :content, presence: true, unless: -> { voice_note.attached? }
  validates :voice_note, file_size: { less_than: 5.megabytes }, allow_nil: true

  scope :not_deleted, -> { where(discarded_at: nil) }
  scope :chronological, -> { order(created_at: :asc) }

  include Discard::Model
end
