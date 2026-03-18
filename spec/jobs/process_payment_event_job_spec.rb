require "rails_helper"

RSpec.describe ProcessPaymentEventJob, type: :job do
  let(:user) { create(:user, status: :lead, plan_tier: :basic) }

  # ── Stripe events ──────────────────────────────────────────────────────────

  describe "stripe: checkout.session.completed" do
    let(:payload) do
      {
        "client_reference_id" => user.id.to_s,
        "customer"            => "cus_stripe123",
        "subscription"        => "sub_stripe123",
        "amount_subtotal"     => 1000,
        "currency"            => "usd"
      }
    end

    it "creates a Subscription and activates the user" do
      described_class.perform_now(
        processor: "stripe",
        event_type: "checkout.session.completed",
        payload: payload
      )

      sub = user.reload.subscription
      expect(sub).not_to be_nil
      expect(sub).to be_active
      expect(sub.external_id).to eq("sub_stripe123")
      expect(sub.external_customer_id).to eq("cus_stripe123")
      expect(user.reload).to be_active
    end
  end

  describe "stripe: invoice.payment_succeeded" do
    let!(:subscription) { create(:subscription, user: user, status: :active, external_id: "sub_stripe123") }
    let(:payload) do
      {
        "subscription"       => "sub_stripe123",
        "lines"              => { "data" => [ { "period" => { "end" => 30.days.from_now.to_i } } ] }
      }
    end

    it "updates current_period_end" do
      described_class.perform_now(
        processor: "stripe",
        event_type: "invoice.payment_succeeded",
        payload: payload
      )
      expect(subscription.reload.current_period_end).to be_within(5.seconds).of(30.days.from_now)
    end
  end

  describe "stripe: invoice.payment_failed" do
    let!(:subscription) { create(:subscription, user: user, status: :active, external_id: "sub_stripe123") }
    let(:payload) { { "subscription" => "sub_stripe123" } }

    it "marks subscription as past_due and creates a CoachAlert" do
      expect {
        described_class.perform_now(
          processor: "stripe",
          event_type: "invoice.payment_failed",
          payload: payload
        )
      }.to change(CoachAlert, :count).by(1)

      expect(subscription.reload).to be_past_due
      alert = CoachAlert.last
      expect(alert.category).to eq("payment_failed")
      expect(alert.user).to eq(user)
    end
  end

  describe "stripe: customer.subscription.deleted" do
    let!(:subscription) { create(:subscription, user: user, status: :active, external_id: "sub_stripe123") }
    let(:payload) { { "id" => "sub_stripe123" } }

    it "cancels subscription and churns user" do
      described_class.perform_now(
        processor: "stripe",
        event_type: "customer.subscription.deleted",
        payload: payload
      )
      expect(subscription.reload).to be_canceled
      expect(user.reload).to be_churned
    end
  end

  # ── MercadoPago events ─────────────────────────────────────────────────────

  describe "mercadopago: preapproval authorized" do
    let(:mp_sub_id) { "mp_sub_123" }
    let(:mp_plan_id) { "mp_plan_basic" }
    let(:payload) do
      {
        "type" => "preapproval",
        "data" => { "id" => mp_sub_id }
      }
    end

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).with(mp_sub_id).and_return({
        "response" => {
          "id" => mp_sub_id,
          "status" => "authorized",
          "external_reference" => user.id.to_s,
          "preapproval_plan_id" => mp_plan_id,
          "payer_id" => "mp_payer_456",
          "next_payment_date" => 30.days.from_now.iso8601
        }
      })
    end

    it "creates Subscription and activates user" do
      described_class.perform_now(
        processor: "mercadopago",
        event_type: "preapproval",
        payload: payload
      )

      sub = user.reload.subscription
      expect(sub).to be_active
      expect(sub.external_id).to eq(mp_sub_id)
      expect(user.reload).to be_active
    end
  end

  describe "mercadopago: payment rejected (recurring charge failure)" do
    let!(:subscription) { create(:subscription, :mercadopago, user: user, status: :active, external_id: "mp_sub_123") }
    let(:payload) { { "type" => "payment", "data" => { "id" => "mp_payment_456" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      payment_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:payment).and_return(payment_double)
      allow(payment_double).to receive(:get).with("mp_payment_456").and_return({
        "response" => {
          "id" => "mp_payment_456",
          "status" => "rejected",
          "metadata" => { "preapproval_id" => "mp_sub_123" }
        }
      })
    end

    it "marks subscription past_due and creates a CoachAlert" do
      expect {
        described_class.perform_now(
          processor: "mercadopago",
          event_type: "payment",
          payload: payload
        )
      }.to change(CoachAlert, :count).by(1)

      expect(subscription.reload).to be_past_due
      expect(CoachAlert.last.category).to eq("payment_failed")
    end
  end

  describe "mercadopago: preapproval cancelled" do
    let!(:subscription) { create(:subscription, :mercadopago, user: user, status: :active, external_id: "mp_sub_123") }
    let(:payload) { { "type" => "preapproval", "data" => { "id" => "mp_sub_123" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).and_return({
        "response" => {
          "id" => "mp_sub_123",
          "status" => "cancelled",
          "external_reference" => user.id.to_s
        }
      })
    end

    it "cancels subscription and churns user" do
      described_class.perform_now(
        processor: "mercadopago",
        event_type: "preapproval",
        payload: payload
      )
      expect(subscription.reload).to be_canceled
      expect(user.reload).to be_churned
    end
  end
end
