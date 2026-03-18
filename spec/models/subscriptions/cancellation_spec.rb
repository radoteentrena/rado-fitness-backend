require "rails_helper"

RSpec.describe Subscriptions::Cancellation do
  describe "#call" do
    context "with a Stripe subscription" do
      let(:subscription) { create(:subscription, processor: :stripe, external_id: "sub_stripe123") }

      it "calls Stripe API and marks cancel_at_period_end" do
        allow(Stripe::Subscription).to receive(:update).and_return(double(cancel_at_period_end: true))

        result = described_class.new(subscription).call

        expect(result[:success]).to be true
        expect(subscription.reload.cancel_at_period_end).to be true
        expect(Stripe::Subscription).to have_received(:update).with(
          "sub_stripe123", { cancel_at_period_end: true }
        )
      end
    end

    context "with a MercadoPago subscription" do
      let(:subscription) { create(:subscription, :mercadopago, external_id: "mp_sub_123") }

      it "calls MP API and marks cancel_at_period_end" do
        sdk_double = instance_double(Mercadopago::SDK)
        preapproval_double = double
        allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
        allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
        allow(preapproval_double).to receive(:update).and_return({ "status" => 200 })

        result = described_class.new(subscription).call

        expect(result[:success]).to be true
        expect(subscription.reload.cancel_at_period_end).to be true
      end
    end
  end
end
