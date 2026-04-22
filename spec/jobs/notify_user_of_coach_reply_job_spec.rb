require "rails_helper"

RSpec.describe NotifyUserOfCoachReplyJob, type: :job do
  let(:user) { create(:user, fcm_token: "sample_fcm_token") }
  let(:conversation) { create(:conversation, user: user) }
  let(:message) { create(:message, conversation: conversation, sender_type: :coach, content: "Coach reply") }
  let(:push_notification) { instance_double(PushNotification, deliver: true) }

  before do
    allow(PushNotification).to receive(:new).and_return(push_notification)
  end

  describe "#perform" do
    context "when message is from coach and user has FCM token" do
      it "delivers a PushNotification with correct args" do
        described_class.perform_now(message.id)

        expect(PushNotification).to have_received(:new).with(
          user: user,
          title: "Respuesta de Rado",
          body: "Coach reply",
          data: { type: "coach_reply", conversation_id: conversation.id.to_s }
        )
        expect(push_notification).to have_received(:deliver)
      end

      it "creates a Notification record" do
        expect {
          described_class.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end

      it "sets notification_type to coach_reply" do
        described_class.perform_now(message.id)
        expect(Notification.last.notification_type).to eq("coach_reply")
      end
    end

    context "when message is from client" do
      let(:client_message) { create(:message, conversation: conversation, sender_type: :client, content: "Client question") }

      it "does not deliver a PushNotification" do
        described_class.perform_now(client_message.id)
        expect(PushNotification).not_to have_received(:new)
      end

      it "does not create a Notification record" do
        expect {
          described_class.perform_now(client_message.id)
        }.not_to change { Notification.count }
      end
    end

    context "when user does not have FCM token" do
      before { user.update!(fcm_token: nil) }

      it "does not raise" do
        expect { described_class.perform_now(message.id) }.not_to raise_error
      end

      it "still creates a Notification record" do
        expect {
          described_class.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end
    end

    context "when message does not exist" do
      it "handles gracefully" do
        expect { described_class.perform_now(99999) }.not_to raise_error
      end
    end

    context "when PushNotification#deliver raises" do
      before { allow(push_notification).to receive(:deliver).and_raise(StandardError, "FCM error") }

      it "still creates a Notification record" do
        expect {
          described_class.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end

      it "does not raise" do
        expect { described_class.perform_now(message.id) }.not_to raise_error
      end
    end

    context "when message content is nil (voice note)" do
      let(:voice_message) do
        msg = create(:message, conversation: conversation, sender_type: :coach, content: "voice message")
        msg.update_column(:content, nil)
        msg
      end

      it "uses fallback body text" do
        described_class.perform_now(voice_message.id)

        expect(PushNotification).to have_received(:new).with(
          hash_including(body: "Mensaje de voz")
        )
      end
    end
  end
end
