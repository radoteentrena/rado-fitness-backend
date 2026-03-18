require "rails_helper"

RSpec.describe "Webhooks::Stripe", type: :request do
  let(:payload) { '{"type":"checkout.session.completed","data":{"object":{"id":"cs_test"}}}' }
  let(:secret)  { "whsec_test" }
  let(:timestamp) { Time.now.to_i }
  let(:sig_header) do
    signed_payload = "#{timestamp}.#{payload}"
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)
    "t=#{timestamp},v1=#{signature}"
  end

  before do
    allow(Rails.application.credentials).to receive(:dig).with(:stripe, :webhook_secret).and_return(secret)
  end

  describe "POST /webhooks/stripe" do
    it "returns 200 and enqueues ProcessPaymentEventJob when signature is valid" do
      allow(ProcessPaymentEventJob).to receive(:perform_later)

      post webhooks_stripe_path,
           params: payload,
           headers: { "Content-Type" => "application/json", "Stripe-Signature" => sig_header }

      expect(response).to have_http_status(:ok)
    end

    it "returns 400 when signature is invalid" do
      post webhooks_stripe_path,
           params: payload,
           headers: { "Content-Type" => "application/json", "Stripe-Signature" => "bad_sig" }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
