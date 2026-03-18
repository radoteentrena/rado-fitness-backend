require "rails_helper"

RSpec.describe Subscriptions::Cancellation do
  describe "#call" do
    let(:subscription) { create(:subscription, external_id: "mp_sub_123") }

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
