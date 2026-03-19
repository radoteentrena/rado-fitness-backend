require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create(:user, plan_tier: :basic) }
  let(:onboarding_profile) { create(:onboarding_profile, user: user, country: "AR") }

  before { sign_in user }

  describe "GET /subscriptions/new" do
    it "returns 200" do
      get new_subscription_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /subscriptions" do
    context "with a valid plan_tier" do
      before { onboarding_profile }

      it "redirects to MercadoPago checkout" do
        allow_any_instance_of(Subscriptions::MercadoPagoCheckout).to receive(:call).and_return(
          { success: true, redirect_url: "https://www.mercadopago.com.ar/subscriptions/checkout" }
        )
        post subscriptions_path, params: { plan_tier: "basic" }
        expect(response).to redirect_to("https://www.mercadopago.com.ar/subscriptions/checkout")
      end

      it "passes the selected plan to the checkout service" do
        checkout_double = instance_double(
          "Subscriptions::MercadoPagoCheckout",
          call: { success: true, redirect_url: "https://www.mercadopago.com.ar/subscriptions/checkout" }
        )
        allow(Subscriptions::MercadoPagoCheckout).to receive(:new).and_return(checkout_double)
        post subscriptions_path, params: { plan_tier: "medium" }
        expect(Subscriptions::MercadoPagoCheckout).to have_received(:new).with(user, "medium")
      end
    end

    context "when checkout fails" do
      before { onboarding_profile }

      it "redirects back to new with alert" do
        allow_any_instance_of(Subscriptions::MercadoPagoCheckout).to receive(:call).and_return(
          { success: false, error: "MP error" }
        )
        post subscriptions_path, params: { plan_tier: "basic" }
        expect(response).to redirect_to(new_subscription_path)
      end
    end

    context "with an invalid plan_tier" do
      it "redirects back with a Spanish alert" do
        post subscriptions_path, params: { plan_tier: "hacker" }
        expect(response).to redirect_to(new_subscription_path)
        expect(flash[:alert]).to match(/Plan inválido/)
      end
    end

    context "with a missing plan_tier" do
      it "redirects back with a Spanish alert" do
        post subscriptions_path
        expect(response).to redirect_to(new_subscription_path)
        expect(flash[:alert]).to match(/Plan inválido/)
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
