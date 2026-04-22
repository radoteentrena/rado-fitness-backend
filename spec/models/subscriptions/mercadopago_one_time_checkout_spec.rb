require "rails_helper"

RSpec.describe Subscriptions::MercadoPagoOneTimeCheckout do
  let(:user)        { create(:user, plan_tier: :basic) }
  let(:profile)     { create(:onboarding_profile, user: user, country: "AR") }
  let(:checkout)    { described_class.new(user, "basic", "monthly") }
  let(:sdk_double)  { instance_double(Mercadopago::SDK) }
  let(:pref_double) { double("preference") }

  before do
    profile
    allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
    allow(sdk_double).to receive(:preference).and_return(pref_double)
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :access_token).and_return("token")
    allow(Rails.application.credentials).to receive(:dig).with(:app_host).and_return("app.example.com")
  end

  describe "#call" do
    context "when MP returns 201" do
      before do
        allow(pref_double).to receive(:create).and_return({
          status: 201,
          response: { "id" => "pref_abc123", "init_point" => "https://mp.com/checkout" }
        })
      end

      it "returns success with redirect_url" do
        result = checkout.call
        expect(result[:success]).to be true
        expect(result[:redirect_url]).to eq("https://mp.com/checkout")
      end

      it "creates a subscription record only after a successful MP response" do
        expect { checkout.call }.to change(Subscription, :count).by(1)
      end

      it "stores the preference_id on the subscription" do
        checkout.call
        expect(Subscription.last.mp_preference_id).to eq("pref_abc123")
      end
    end

    context "when MP returns a non-201 status" do
      before do
        allow(pref_double).to receive(:create).and_return({ status: 500, response: {} })
      end

      it "returns failure" do
        result = checkout.call
        expect(result[:success]).to be false
      end

      it "does NOT create a subscription record" do
        expect { checkout.call }.not_to change(Subscription, :count)
      end
    end

    context "when MP raises an exception" do
      before do
        allow(pref_double).to receive(:create).and_raise(StandardError, "network error")
      end

      it "returns failure" do
        result = checkout.call
        expect(result[:success]).to be false
      end

      it "does NOT create a subscription record" do
        expect { checkout.call }.not_to change(Subscription, :count)
      end
    end
  end
end
