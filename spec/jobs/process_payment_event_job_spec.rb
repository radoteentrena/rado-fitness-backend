require "rails_helper"

RSpec.describe ProcessPaymentEventJob, type: :job do
  let(:user) { create(:user, status: :lead, plan_tier: :basic) }

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

      sub = user.reload.active_subscription
      expect(sub).to be_active
      expect(sub.external_id).to eq(mp_sub_id)
      expect(user.reload).to be_active
    end
  end

  describe "mercadopago: payment rejected (recurring charge failure)" do
    let!(:subscription) { create(:subscription, user: user, status: :active, external_id: "mp_sub_123") }
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
    let!(:subscription) do
      create(:subscription, user: user, status: :active, external_id: "mp_sub_123",
                            current_period_end: nil)
    end
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

    it "cancels the subscription identified by external_id, not an arbitrary row" do
      other_sub = create(:subscription, user: user, status: :active, external_id: "mp_other_999")

      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )

      expect(subscription.reload).to be_canceled
      expect(other_sub.reload).to be_active
    end

    it "locks access immediately when current_period_end is nil" do
      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )
      expect(user.reload).to be_access_locked
    end

    it "does NOT lock access when current_period_end is still in the future" do
      subscription.update!(current_period_end: 10.days.from_now)

      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )

      expect(user.reload).not_to be_access_locked
    end

    it "churns user regardless of period end" do
      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )
      expect(user.reload).to be_churned
    end
  end
end
