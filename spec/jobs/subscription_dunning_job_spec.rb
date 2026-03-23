require "rails_helper"

RSpec.describe SubscriptionDunningJob, type: :job do
  let(:user) { create(:user, status: :active) }

  describe "one-time expired subscriptions" do
    let!(:subscription) do
      create(:subscription, :one_time,
        user: user,
        status: :active,
        access_expires_at: expires_at,
        reminded_at: nil
      )
    end

    context "when expired today (day 0)" do
      let(:expires_at) { Time.current - 1.hour }

      it "sends a reminder email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(SubscriptionReminderMailer, :reminder)
      end

      it "updates reminded_at" do
        described_class.perform_now
        expect(subscription.reload.reminded_at).to be_present
      end

      it "does not lock the user" do
        described_class.perform_now
        expect(user.reload).not_to be_access_locked
      end
    end

    context "when expired 5 days ago" do
      let(:expires_at) { 5.days.ago }

      it "locks the user" do
        described_class.perform_now
        expect(user.reload).to be_access_locked
      end

      it "cancels the subscription" do
        described_class.perform_now
        expect(subscription.reload).to be_canceled
      end
    end

    context "when already reminded today" do
      let(:expires_at) { Time.current - 1.hour }

      before { subscription.update!(reminded_at: 1.hour.ago) }

      it "does not send duplicate reminders" do
        expect { described_class.perform_now }
          .not_to have_enqueued_mail(SubscriptionReminderMailer, :reminder)
      end
    end
  end

  describe "recurring past_due subscriptions" do
    let!(:subscription) do
      create(:subscription,
        user: user,
        billing_type: :recurring,
        status: :past_due,
        past_due_since: past_due_since,
        reminded_at: nil
      )
    end

    context "when past_due today (day 0)" do
      let(:past_due_since) { Time.current }

      it "sends a reminder email" do
        expect { described_class.perform_now }
          .to have_enqueued_mail(SubscriptionReminderMailer, :reminder)
      end
    end

    context "when past_due for 5 days" do
      let(:past_due_since) { 5.days.ago }

      it "locks the user" do
        described_class.perform_now
        expect(user.reload).to be_access_locked
      end

      it "does not cancel recurring subscription" do
        described_class.perform_now
        expect(subscription.reload).to be_past_due
      end
    end
  end
end
