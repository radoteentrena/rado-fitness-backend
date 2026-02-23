class AiConversation < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :program, optional: true
  has_many :ai_messages, dependent: :destroy

  validates :objectives, presence: true

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }

  def add_message!(role:, content:, structured_data: nil)
    ai_messages.create!(role: role, content: content, structured_data: structured_data)
  end

  def message_history
    ai_messages.order(:created_at).map do |msg|
      { role: msg.role, content: msg.content }
    end
  end
end
