require "rails_helper"

RSpec.describe Subscriptions::StripeCheckout do
  let(:user) { create(:user, plan_tier: :basic) }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :secret_key).and_return("sk_test_fake")
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :prices, :basic).and_return("price_basic_test")
    allow(Rails.application.credentials).to receive(:dig).with(:app_host).and_return("example.com")

    # Routes don't exist until Task 7 — stub url_helpers without partial double verification
    url_helpers = double(
      subscriptions_processing_url: "http://example.com/subscriptions/processing",
      new_subscription_url: "http://example.com/subscriptions/new"
    )
    allow(Rails.application.routes).to receive(:url_helpers).and_return(url_helpers)
  end

  describe "#call" do
    context "when Stripe succeeds" do
      before do
        allow(Stripe::Customer).to receive(:create).and_return(
          double(id: "cus_test123")
        )
        allow(Stripe::Checkout::Session).to receive(:create).and_return(
          double(url: "https://checkout.stripe.com/pay/cs_test_abc")
        )
      end

      it "returns success with a redirect_url" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be true
        expect(result[:redirect_url]).to eq("https://checkout.stripe.com/pay/cs_test_abc")
      end

      it "creates a Stripe customer with user email" do
        expect(Stripe::Customer).to receive(:create).with(
          hash_including(email: user.email)
        ).and_return(double(id: "cus_test123"))
        allow(Stripe::Checkout::Session).to receive(:create).and_return(
          double(url: "https://checkout.stripe.com/pay/cs_test_abc")
        )
        described_class.new(user, :basic).call
      end

      it "sets client_reference_id to user.id for webhook lookup" do
        allow(Stripe::Customer).to receive(:create).and_return(double(id: "cus_test123"))
        expect(Stripe::Checkout::Session).to receive(:create).with(
          hash_including(client_reference_id: user.id.to_s)
        ).and_return(double(url: "https://checkout.stripe.com/pay/cs_test_abc"))
        described_class.new(user, :basic).call
      end
    end

    context "when Stripe raises an error" do
      before do
        allow(Stripe::Customer).to receive(:create).and_raise(
          Stripe::StripeError.new("Card declined")
        )
      end

      it "returns failure with error message" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end
end
