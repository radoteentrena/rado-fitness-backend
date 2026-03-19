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

    it "enforces one subscription per user at model level" do
      user = create(:user)
      create(:subscription, user: user)
      duplicate = build(:subscription, user: user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe "enums" do
    it "has processor enum with mercadopago" do
      expect(Subscription.processors.keys).to contain_exactly("mercadopago")
    end

    it "has status enum with pending, active, past_due, canceled" do
      expect(Subscription.statuses.keys).to contain_exactly("pending", "active", "past_due", "canceled")
    end
  end

  describe "#amount_in_dollars" do
    it "returns amount_cents divided by 100" do
      sub = build(:subscription, amount_cents: 10000)
      expect(sub.amount_in_dollars).to eq(100.0)
    end
  end
end
