require "rails_helper"

RSpec.describe PaymentReminderJob, type: :job do
  let(:user) { create(:user, status: :active, fcm_token: "device_token_123") }

  before do
    allow(PushNotification).to receive(:new).and_return(double(deliver: true))
  end

  describe "recurring subscriptions expiring in 2 days" do
    let!(:subscription) do
      create(:subscription, user: user, billing_type: :recurring,
        current_period_end: 2.days.from_now.middle_of_day)
    end

    it "sends a push notification to the user" do
      described_class.perform_now
      expect(PushNotification).to have_received(:new).with(
        user: user,
        title: "Tu acceso vence en 2 días",
        body: "Renovar ahora para no perder tu plan",
        data: { type: "payment_reminder" }
      )
    end
  end

  describe "one-time subscriptions expiring in 2 days" do
    let!(:subscription) do
      create(:subscription, :one_time, user: user,
        access_expires_at: 2.days.from_now.middle_of_day)
    end

    it "sends a push notification to the user" do
      described_class.perform_now
      expect(PushNotification).to have_received(:new).with(
        user: user,
        title: "Tu acceso vence en 2 días",
        body: "Renovar ahora para no perder tu plan",
        data: { type: "payment_reminder" }
      )
    end
  end

  describe "subscriptions NOT expiring in 2 days" do
    let!(:subscription) do
      create(:subscription, user: user, billing_type: :recurring,
        current_period_end: 5.days.from_now)
    end

    it "does not send a notification" do
      described_class.perform_now
      expect(PushNotification).not_to have_received(:new)
    end
  end

  describe "canceled subscription expiring in 2 days" do
    let!(:subscription) do
      create(:subscription, :canceled, user: user, billing_type: :recurring,
        current_period_end: 2.days.from_now.middle_of_day)
    end

    it "does not send a notification" do
      described_class.perform_now
      expect(PushNotification).not_to have_received(:new)
    end
  end

  describe "user without fcm_token" do
    let(:user_no_token) { create(:user, status: :active, fcm_token: nil) }
    let!(:subscription) do
      create(:subscription, user: user_no_token, billing_type: :recurring,
        current_period_end: 2.days.from_now.middle_of_day)
    end

    it "skips users without a device token" do
      described_class.perform_now
      expect(PushNotification).not_to have_received(:new)
    end
  end

  describe "deduplication — multiple subscriptions for same user" do
    let!(:sub1) do
      create(:subscription, user: user, billing_type: :recurring,
        current_period_end: 2.days.from_now.middle_of_day)
    end
    let!(:sub2) do
      create(:subscription, :one_time, user: user,
        access_expires_at: 2.days.from_now.middle_of_day)
    end

    it "sends only one notification per user" do
      described_class.perform_now
      expect(PushNotification).to have_received(:new).once
    end
  end
end
