require "rails_helper"

RSpec.describe Subscriptions::MercadoPagoCheckout do
  let(:user) { create(:user, plan_tier: :basic) }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :access_token).and_return("TEST-fake-access-token")
    allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :plans, :basic).and_return("2c93808488a30f74018917dcc3830013")
    allow(Rails.application.credentials).to receive(:dig).with(:app_host).and_return("example.com")

    # Routes don't exist until Task 7 — stub url_helpers without partial double verification
    url_helpers = double(
      subscriptions_processing_url: "http://example.com/subscriptions/processing"
    )
    allow(Rails.application.routes).to receive(:url_helpers).and_return(url_helpers)
  end

  describe "#call" do
    context "when MercadoPago succeeds" do
      let(:mp_client) { instance_double(Mercadopago::SDK) }
      let(:mp_preapproval) { double }

      before do
        allow(Mercadopago::SDK).to receive(:new).and_return(mp_client)
        allow(mp_client).to receive(:preapproval).and_return(mp_preapproval)
        allow(mp_preapproval).to receive(:create).and_return(
          { "status" => 201, "response" => { "init_point" => "https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=xxx" } }
        )
      end

      it "returns success with a redirect_url" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be true
        expect(result[:redirect_url]).to include("mercadopago.com.ar")
      end

      it "sets external_reference to user.id for webhook lookup" do
        expect(mp_preapproval).to receive(:create).with(
          hash_including("external_reference" => user.id.to_s)
        ).and_return(
          { "status" => 201, "response" => { "init_point" => "https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=xxx" } }
        )
        described_class.new(user, :basic).call
      end
    end

    context "when MercadoPago returns an error status" do
      let(:mp_client) { instance_double(Mercadopago::SDK) }
      let(:mp_preapproval) { double }

      before do
        allow(Mercadopago::SDK).to receive(:new).and_return(mp_client)
        allow(mp_client).to receive(:preapproval).and_return(mp_preapproval)
        allow(mp_preapproval).to receive(:create).and_return(
          { "status" => 400, "response" => { "message" => "invalid plan" } }
        )
      end

      it "returns failure" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
      end
    end
  end
end
