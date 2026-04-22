require 'rails_helper'

RSpec.describe NotifyUserOfCoachReplyJob, type: :job do
  let(:user) { create(:user, fcm_token: 'sample_fcm_token') }
  let(:conversation) { create(:conversation, user: user) }
  let(:message) { create(:message, conversation: conversation, sender_type: :coach, content: "Coach reply") }

  describe '#perform' do
    context 'when message is from coach and user has FCM token' do
      it 'sends FCM notification' do
        allow_any_instance_of(NotifyUserOfCoachReplyJob).to receive(:send_fcm_notification)

        expect_any_instance_of(NotifyUserOfCoachReplyJob).to receive(:send_fcm_notification)
          .with(user, message)

        NotifyUserOfCoachReplyJob.perform_now(message.id)
      end

      it 'creates a notification record' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end

      it 'sets notification type to coach_reply' do
        NotifyUserOfCoachReplyJob.perform_now(message.id)
        notification = Notification.last

        expect(notification.notification_type).to eq('coach_reply')
      end
    end

    context 'when message is from client' do
      let(:client_message) { create(:message, conversation: conversation, sender_type: :client, content: "Client question") }

      it 'does not send FCM notification' do
        allow_any_instance_of(NotifyUserOfCoachReplyJob).to receive(:send_fcm_notification)

        expect_any_instance_of(NotifyUserOfCoachReplyJob).not_to receive(:send_fcm_notification)

        NotifyUserOfCoachReplyJob.perform_now(client_message.id)
      end

      it 'does not create notification record' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(client_message.id)
        }.not_to change { Notification.count }
      end
    end

    context 'when user does not have FCM token' do
      before do
        user.update(fcm_token: nil)
      end

      it 'does not send FCM notification' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(message.id)
        }.not_to raise_error

        # Should still create notification record even without FCM token
        expect(Notification.count).to eq(1)
      end
    end

    context 'when message does not exist' do
      it 'handles gracefully' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(99999)
        }.not_to raise_error
      end
    end

    context 'when FCM send fails' do
      before do
        allow_any_instance_of(NotifyUserOfCoachReplyJob).to receive(:send_fcm_notification).and_raise(StandardError.new("FCM Error"))
      end

      it 'still creates notification record' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(message.id)
        }.to change { Notification.count }.by(1)
      end

      it 'does not raise error' do
        expect {
          NotifyUserOfCoachReplyJob.perform_now(message.id)
        }.not_to raise_error
      end
    end
  end
end
