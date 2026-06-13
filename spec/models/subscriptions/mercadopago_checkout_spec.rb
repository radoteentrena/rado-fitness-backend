require "rails_helper"

RSpec.describe Subscriptions::MercadoPagoCheckout do
  let(:user) { create(:user, plan_tier: :basic) }
  let(:plan_id) { "2c93808488a30f74018917dcc3830013" }
  let(:init_point) { "https://www.mercadopago.com.ar/subscriptions/checkout?preapproval_plan_id=xxx" }

  let(:mp_client) { instance_double(Mercadopago::SDK) }
  let(:preapproval_plan) { double }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :access_token).and_return("TEST-token")
    allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :plans, :basic_monthly).and_return(plan_id)

    allow(Mercadopago::SDK).to receive(:new).and_return(mp_client)
    allow(mp_client).to receive(:preapproval_plan).and_return(preapproval_plan)
    allow(preapproval_plan).to receive(:get).with(plan_id).and_return(
      { status: 200, response: { "init_point" => init_point } }
    )
  end

  describe "#call" do
    context "when MercadoPago succeeds" do
      it "returns success and appends payer_email and external_reference to the redirect" do
        result = described_class.new(user, :basic).call

        expect(result[:success]).to be true
        expect(result[:redirect_url]).to include("payer_email=#{CGI.escape(user.email)}")
        expect(result[:redirect_url]).to include("external_reference=#{user.id}")
      end

      it "creates a pending recurring subscription carrying the chosen plan_tier" do
        expect { described_class.new(user, :basic).call }
          .to change { user.subscriptions.where(billing_type: :recurring, status: :pending).count }.by(1)

        sub = user.subscriptions.find_by(billing_type: :recurring, status: :pending)
        expect(sub.plan_tier).to eq("basic")
        expect(sub.frequency).to eq("monthly")
        expect(sub.external_plan_id).to eq(plan_id)
      end

      it "reuses an existing pending recurring subscription instead of duplicating" do
        create(:subscription, user: user, billing_type: :recurring, status: :pending, plan_tier: :medium)

        expect { described_class.new(user, :basic).call }
          .not_to change { user.subscriptions.where(billing_type: :recurring, status: :pending).count }

        expect(user.subscriptions.find_by(billing_type: :recurring, status: :pending).plan_tier).to eq("basic")
      end
    end

    context "when the plan is not configured" do
      before do
        allow(Rails.application.credentials).to receive(:dig).with(:mercadopago, :plans, :basic_monthly).and_return(nil)
      end

      it "returns failure without creating a subscription" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be false
        expect(user.subscriptions.count).to eq(0)
      end
    end

    context "when MercadoPago returns an error status" do
      before do
        allow(preapproval_plan).to receive(:get).with(plan_id).and_return(
          { status: 400, response: { "message" => "invalid plan" } }
        )
      end

      it "returns failure without creating a subscription" do
        result = described_class.new(user, :basic).call
        expect(result[:success]).to be false
        expect(result[:error]).to be_present
        expect(user.subscriptions.count).to eq(0)
      end
    end
  end
end
