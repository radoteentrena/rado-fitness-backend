require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "associations" do
    it "belongs to user" do
      association = Conversation.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many messages with dependent destroy" do
      association = Conversation.reflect_on_association(:messages)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "validates presence of user_id" do
      conversation = build(:conversation, user_id: nil)
      expect(conversation).not_to be_valid
      expect(conversation.errors[:user_id]).to be_present
    end

    it "validates uniqueness of user_id" do
      user = create(:user)
      create(:conversation, user: user)
      conversation = build(:conversation, user: user)
      expect(conversation).not_to be_valid
      expect(conversation.errors[:user_id]).to be_present
    end
  end

  describe "scopes" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    before do
      create(:conversation, user: user1, last_message_at: 2.hours.ago)
      create(:conversation, user: user2, last_message_at: 1.hour.ago)
    end

    it "orders by last_message_at descending" do
      conversations = Conversation.order_by_recent
      expect(conversations.first.user).to eq(user2)
      expect(conversations.second.user).to eq(user1)
    end
  end
end
