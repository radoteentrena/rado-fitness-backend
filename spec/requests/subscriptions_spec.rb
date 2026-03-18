require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create(:user, plan_tier: :basic) }
  let(:onboarding_profile) { create(:onboarding_profile, user: user, country: "US") }

  before { sign_in user }

  describe "GET /subscriptions/new" do
    it "returns 200" do
      get new_subscription_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /subscriptions" do
    context "with international client (Stripe)" do
      before { onboarding_profile }

      it "redirects to Stripe checkout" do
        allow_any_instance_of(Subscriptions::StripeCheckout).to receive(:call).and_return(
          { success: true, redirect_url: "https://checkout.stripe.com/pay/cs_test_abc" }
        )
        post subscriptions_path
        expect(response).to redirect_to("https://checkout.stripe.com/pay/cs_test_abc")
      end
    end

    context "with Argentine client (MercadoPago)" do
      let(:ar_profile) { create(:onboarding_profile, user: user, country: "AR") }

      before { ar_profile }

      it "redirects to MercadoPago checkout" do
        allow_any_instance_of(Subscriptions::MercadoPagoCheckout).to receive(:call).and_return(
          { success: true, redirect_url: "https://www.mercadopago.com.ar/subscriptions/checkout" }
        )
        post subscriptions_path
        expect(response).to redirect_to("https://www.mercadopago.com.ar/subscriptions/checkout")
      end
    end

    context "when checkout fails" do
      before { onboarding_profile }

      it "redirects back to new with alert" do
        allow_any_instance_of(Subscriptions::StripeCheckout).to receive(:call).and_return(
          { success: false, error: "Card declined" }
        )
        post subscriptions_path
        expect(response).to redirect_to(new_subscription_path)
      end
    end
  end

  describe "GET /subscriptions/processing" do
    it "returns 200" do
      get subscriptions_processing_path
      expect(response).to have_http_status(:ok)
    end
  end
end
