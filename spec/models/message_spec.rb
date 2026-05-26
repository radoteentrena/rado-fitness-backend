require "rails_helper"

RSpec.describe Message, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to have_one_attached(:voice_note) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:conversation_id) }
    it { is_expected.to validate_presence_of(:sender_type) }
  end

  describe "content validation" do
    let(:conversation) { create(:conversation) }

    it "requires content if no voice_note" do
      message = Message.new(conversation: conversation, sender_type: :client)
      expect(message.valid?).to be false
      expect(message.errors[:content]).to be_present
    end

    it "allows message with voice_note and no content" do
      message = build(:message, conversation: conversation, content: nil)
      message.voice_note.attach(fixture_file_upload("test.webm", "audio/webm"))
      expect(message.valid?).to be true
    end
  end

  describe "soft delete via discard" do
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation, content: "Test message") }

    it "soft deletes message" do
      expect { message.discard }.to change { message.discarded_at }
      expect(message.discarded?).to be true
    end

    it "filters deleted messages with not_deleted scope" do
      message
      other_message = create(:message, conversation: conversation)
      message.discard

      expect(Message.not_deleted).to include(other_message)
      expect(Message.not_deleted).not_to include(message)
    end
  end

  describe "ActionCable broadcast" do
    let(:conversation) { create(:conversation) }

    it "broadcasts to admin_nav when a client message is created" do
      expect {
        create(:message, conversation: conversation, sender_type: :client, content: "hola")
      }.to have_broadcasted_to("admin_nav").from_channel(Turbo::StreamsChannel)
    end

    it "does not broadcast when a coach message is created" do
      expect {
        create(:message, conversation: conversation, sender_type: :coach, content: "reply")
      }.not_to have_broadcasted_to("admin_nav").from_channel(Turbo::StreamsChannel)
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:sender_type).backed_by_column_of_type(:string).with_values(client: "client", coach: "coach", system: "system") }
  end

  describe "scopes" do
    let(:conversation) { create(:conversation) }

    before do
      @message1 = create(:message, conversation: conversation, created_at: 2.days.ago)
      @message2 = create(:message, conversation: conversation, created_at: 1.day.ago)
      @message3 = create(:message, conversation: conversation, created_at: 1.hour.ago)
    end

    describe ".chronological" do
      it "orders messages by created_at ascending" do
        expect(Message.chronological).to eq([@message1, @message2, @message3])
      end
    end
  end
end
