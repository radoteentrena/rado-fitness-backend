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

  describe "cancelled recurring subscriptions past period end" do
    let(:user) { create(:user, access_status: :active) }

    it "locks access when current_period_end has passed" do
      create(:subscription,
        user:               user,
        billing_type:       :recurring,
        status:             :canceled,
        current_period_end: 2.days.ago
      )

      described_class.perform_now
      expect(user.reload).to be_access_locked
    end

    it "does NOT lock access when current_period_end is still in the future" do
      create(:subscription,
        user:               user,
        billing_type:       :recurring,
        status:             :canceled,
        current_period_end: 5.days.from_now
      )

      described_class.perform_now
      expect(user.reload).not_to be_access_locked
    end
  end

  describe "deduplication: user with both one-time expired and recurring past_due" do
    let(:user) { create(:user) }

    it "sends only one reminder when both subscription types are overdue for the same user" do
      create(:subscription,
        user:              user,
        billing_type:      :one_time,
        status:            :active,
        access_expires_at: 2.days.ago,
        reminded_at:       nil
      )
      create(:subscription,
        user:           user,
        billing_type:   :recurring,
        status:         :past_due,
        past_due_since: 2.days.ago,
        reminded_at:    nil
      )

      expect(SubscriptionReminderMailer).to receive(:reminder).once.and_call_original
      allow_any_instance_of(ActionMailer::MessageDelivery).to receive(:deliver_later)

      described_class.perform_now
    end
  end
end
