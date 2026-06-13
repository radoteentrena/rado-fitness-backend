require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
  let(:user) { create(:user, plan_tier: :basic) }
  let(:onboarding_profile) { create(:onboarding_profile, user: user, country: "AR") }

  before { sign_in user }

  describe "GET /subscription/new" do
    it "returns 200" do
      get new_subscription_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /subscription/frequency" do
    it "returns 200 with a valid plan_tier" do
      get subscription_frequency_path, params: { plan_tier: "basic" }
      expect(response).to have_http_status(:ok)
    end

    it "redirects with invalid plan_tier" do
      get subscription_frequency_path, params: { plan_tier: "hacker" }
      expect(response).to redirect_to(new_subscription_path)
    end
  end

  describe "POST /subscription" do
    context "with recurring billing" do
      before { onboarding_profile }

      it "redirects to MercadoPago checkout" do
        allow_any_instance_of(Subscriptions::MercadoPagoCheckout).to receive(:call).and_return(
          { success: true, redirect_url: "https://www.mercadopago.com.ar/subscriptions/checkout" }
        )
        post subscriptions_path, params: { plan_tier: "basic", billing_type: "recurring", frequency: "monthly" }
        expect(response).to redirect_to("https://www.mercadopago.com.ar/subscriptions/checkout")
      end

      it "passes the selected plan and frequency to the checkout service" do
        checkout_double = instance_double(
          "Subscriptions::MercadoPagoCheckout",
          call: { success: true, redirect_url: "https://www.mercadopago.com.ar/subscriptions/checkout" }
        )
        allow(Subscriptions::MercadoPagoCheckout).to receive(:new).and_return(checkout_double)
        post subscriptions_path, params: { plan_tier: "medium", billing_type: "recurring", frequency: "quarterly" }
        expect(Subscriptions::MercadoPagoCheckout).to have_received(:new).with(user, "medium", "quarterly")
      end
    end

    context "with one_time billing" do
      before { onboarding_profile }

      it "routes to the one-time checkout service" do
        checkout_double = instance_double(
          "Subscriptions::MercadoPagoOneTimeCheckout",
          call: { success: true, redirect_url: "https://www.mercadopago.com.ar/checkout/v1" }
        )
        allow(Subscriptions::MercadoPagoOneTimeCheckout).to receive(:new).and_return(checkout_double)
        post subscriptions_path, params: { plan_tier: "basic", billing_type: "one_time", frequency: "monthly" }
        expect(response).to redirect_to("https://www.mercadopago.com.ar/checkout/v1")
        expect(Subscriptions::MercadoPagoOneTimeCheckout).to have_received(:new).with(user, "basic", "monthly")
      end
    end

    context "when checkout fails" do
      before { onboarding_profile }

      it "redirects back to new with alert" do
        allow_any_instance_of(Subscriptions::MercadoPagoCheckout).to receive(:call).and_return(
          { success: false, error: "MP error" }
        )
        post subscriptions_path, params: { plan_tier: "basic", billing_type: "recurring", frequency: "monthly" }
        expect(response).to redirect_to(new_subscription_path)
      end
    end

    context "with an invalid plan_tier" do
      it "redirects back with a Spanish alert" do
        post subscriptions_path, params: { plan_tier: "hacker", billing_type: "recurring", frequency: "monthly" }
        expect(response).to redirect_to(new_subscription_path)
        expect(flash[:alert]).to match(/Plan inválido/)
      end
    end

    context "with a missing billing_type or frequency" do
      it "redirects to frequency selector" do
        post subscriptions_path, params: { plan_tier: "basic" }
        expect(response).to redirect_to(subscription_frequency_path(plan_tier: "basic"))
        expect(flash[:alert]).to match(/frecuencia válida/)
      end
    end
  end

  describe "GET /subscription/processing" do
    it "redirects to root with an unknown status" do
      get subscriptions_processing_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects to new_subscription when payment is rejected" do
      get subscriptions_processing_path, params: { status: "rejected" }
      expect(response).to redirect_to(new_subscription_path)
    end
  end
end
