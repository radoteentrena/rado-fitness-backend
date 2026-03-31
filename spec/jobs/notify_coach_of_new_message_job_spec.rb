require 'rails_helper'

RSpec.describe NotifyCoachOfNewMessageJob, type: :job do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation, user: user) }
  let(:message) { create(:message, conversation: conversation, sender_type: :client, content: "Test message") }

  describe '#perform' do
    context 'when message is from client' do
      it 'enqueues admin notification' do
        expect(AdminNotification).to receive(:notify).with(
          hash_including(
            title: "Nuevo mensaje de #{user.first_name}",
            body: message.content,
            action_url: "/admin/conversations/#{conversation.id}"
          )
        )

        NotifyCoachOfNewMessageJob.perform_now(message.id)
      end

      it 'creates a notification record' do
        allow(AdminNotification).to receive(:notify)

        expect {
          NotifyCoachOfNewMessageJob.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end

      it 'sets notification type to new_message' do
        allow(AdminNotification).to receive(:notify)

        NotifyCoachOfNewMessageJob.perform_now(message.id)
        notification = Notification.last

        expect(notification.notification_type).to eq('new_message')
      end
    end

    context 'when message is from coach' do
      let(:coach_message) { create(:message, conversation: conversation, sender_type: :coach, content: "Coach reply") }

      it 'does not enqueue notification' do
        expect(AdminNotification).not_to receive(:notify)

        NotifyCoachOfNewMessageJob.perform_now(coach_message.id)
      end

      it 'does not create notification record' do
        expect {
          NotifyCoachOfNewMessageJob.perform_now(coach_message.id)
        }.not_to change { Notification.count }
      end
    end

    context 'when message does not exist' do
      it 'handles gracefully' do
        expect(AdminNotification).not_to receive(:notify)

        expect {
          NotifyCoachOfNewMessageJob.perform_now(99999)
        }.not_to raise_error
      end
    end

  end
end
