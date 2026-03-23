require "rails_helper"

RSpec.describe Subscription, type: :model do
  describe "associations" do
    it "belongs to user" do
      sub = build(:subscription)
      expect(sub.user).to be_present
    end
  end

  describe "validations" do
    it "is valid with all required fields" do
      sub = build(:subscription)
      expect(sub).to be_valid
    end

    it "requires processor" do
      sub = build(:subscription, processor: nil)
      expect(sub).not_to be_valid
    end

    it "requires plan_tier" do
      sub = build(:subscription, plan_tier: nil)
      expect(sub).not_to be_valid
    end

    it "allows multiple subscriptions per user" do
      user = create(:user)
      create(:subscription, user: user)
      second = build(:subscription, user: user, status: :pending)
      expect(second).to be_valid
    end

    context "one_time billing_type" do
      it "is valid with monthly frequency" do
        sub = build(:subscription, :one_time)
        expect(sub).to be_valid
      end

      it "is invalid with quarterly frequency" do
        sub = build(:subscription, billing_type: :one_time, frequency: :quarterly)
        expect(sub).not_to be_valid
        expect(sub.errors[:frequency]).to be_present
      end

      it "is invalid with yearly frequency" do
        sub = build(:subscription, billing_type: :one_time, frequency: :yearly)
        expect(sub).not_to be_valid
      end
    end

    context "recurring billing_type" do
      it "is valid with any frequency" do
        %i[monthly quarterly yearly].each do |freq|
          sub = build(:subscription, billing_type: :recurring, frequency: freq)
          expect(sub).to be_valid
        end
      end
    end
  end

  describe "enums" do
    it "has processor enum with mercadopago" do
      expect(Subscription.processors.keys).to contain_exactly("mercadopago")
    end

    it "has status enum with pending, active, past_due, canceled" do
      expect(Subscription.statuses.keys).to contain_exactly("pending", "active", "past_due", "canceled")
    end

    it "has billing_type enum with recurring and one_time" do
      expect(Subscription.billing_types.keys).to contain_exactly("recurring", "one_time")
    end

    it "has frequency enum with monthly, quarterly, yearly" do
      expect(Subscription.frequencies.keys).to contain_exactly("monthly", "quarterly", "yearly")
    end
  end

  describe "#amount_in_dollars" do
    it "returns amount_cents divided by 100" do
      sub = build(:subscription, amount_cents: 10000)
      expect(sub.amount_in_dollars).to eq(100.0)
    end
  end
end
