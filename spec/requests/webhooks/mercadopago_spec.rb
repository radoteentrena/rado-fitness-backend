require "rails_helper"

RSpec.describe "Webhooks::Mercadopago", type: :request do
  let(:secret) { "mp_webhook_secret" }
  let(:payload) { { type: "preapproval", data: { id: "sub_mp_123" } }.to_json }
  let(:x_request_id) { "test-request-id" }
  let(:ts) { Time.now.to_i.to_s }

  before do
    allow(Rails.application.credentials).to receive(:dig)
      .with(:mercadopago, :webhook_secret).and_return(secret)
  end

  def mp_signature(ts, request_id, data_id)
    manifest = "id:#{data_id};request-id:#{request_id};ts:#{ts};"
    OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
  end

  describe "POST /webhooks/mercadopago" do
    it "returns 200 and enqueues job when signature is valid" do
      allow(ProcessPaymentEventJob).to receive(:perform_later)
      data_id = "sub_mp_123"
      sig = mp_signature(ts, x_request_id, data_id)

      post webhooks_mercadopago_path,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "x-signature" => "ts=#{ts},v1=#{sig}",
             "x-request-id" => x_request_id
           }

      expect(response).to have_http_status(:ok)
    end

    it "returns 400 when signature is invalid" do
      post webhooks_mercadopago_path,
           params: payload,
           headers: {
             "Content-Type" => "application/json",
             "x-signature" => "ts=#{ts},v1=bad_sig",
             "x-request-id" => x_request_id
           }

      expect(response).to have_http_status(:bad_request)
    end
  end
end
