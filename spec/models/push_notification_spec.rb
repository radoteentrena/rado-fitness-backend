require "rails_helper"

RSpec.describe PushNotification do
  let(:user) { build(:user, fcm_token: "test_device_token") }
  let(:notification) do
    described_class.new(
      user: user,
      title: "Título",
      body: "Cuerpo del mensaje",
      data: { type: "coach_reply", conversation_id: "42" }
    )
  end

  after { PushNotification.instance_variable_set(:@fcm_client, nil) }

  describe "#deliver" do
    context "when user has no fcm_token" do
      before { user.fcm_token = nil }

      it "returns false without calling FCM" do
        expect(FCM).not_to receive(:new)
        expect(notification.deliver).to be false
      end
    end

    context "when FCM returns success" do
      let(:fcm_client) { instance_double(FCM) }

      before do
        allow(FCM).to receive(:new).and_return(fcm_client)
        allow(fcm_client).to receive(:send_v1).and_return({ status_code: 200 })
      end

      it "returns true" do
        expect(notification.deliver).to be true
      end

      it "sends to correct device token" do
        expect(fcm_client).to receive(:send_v1).with(
          hash_including(token: "test_device_token")
        )
        notification.deliver
      end

      it "includes notification title and body" do
        expect(fcm_client).to receive(:send_v1).with(
          hash_including(
            notification: { title: "Título", body: "Cuerpo del mensaje" }
          )
        )
        notification.deliver
      end

      it "includes data payload with stringified values" do
        expect(fcm_client).to receive(:send_v1).with(
          hash_including(
            data: { "type" => "coach_reply", "conversation_id" => "42" }
          )
        )
        notification.deliver
      end
    end

    context "when FCM returns non-200 status" do
      let(:fcm_client) { instance_double(FCM) }

      before do
        allow(FCM).to receive(:new).and_return(fcm_client)
        allow(fcm_client).to receive(:send_v1).and_return({ status_code: 400 })
      end

      it "returns false" do
        expect(notification.deliver).to be false
      end
    end

    context "when FCM raises an error" do
      let(:fcm_client) { instance_double(FCM) }

      before do
        allow(FCM).to receive(:new).and_return(fcm_client)
        allow(fcm_client).to receive(:send_v1).and_raise(StandardError, "FCM error")
      end

      it "returns false without raising" do
        expect { notification.deliver }.not_to raise_error
        expect(notification.deliver).to be false
      end
    end
  end
end
