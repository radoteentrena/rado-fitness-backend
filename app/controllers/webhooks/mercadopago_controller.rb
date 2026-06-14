module Webhooks
  class MercadoPagoController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      # Read body once — reused for both signature verification and job payload
      raw_body = request.body.read
      body = JSON.parse(raw_body)

      return head :bad_request unless valid_signature?(body)

      topic = body["type"] || params[:topic]

      ProcessPaymentEventJob.perform_later(
        processor: "mercadopago",
        event_type: topic,
        payload: body.deep_stringify_keys
      )

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def valid_signature?(body)
      secret = Rails.application.credentials.dig(:mercadopago, :webhook_secret)
      unless secret
        Rails.logger.warn("[MPWebhookDEBUG] no webhook_secret in credentials")
        return false
      end

      x_signature  = request.headers["x-signature"]
      x_request_id = request.headers["x-request-id"]

      # TEMP DIAGNOSTIC — remove after root cause confirmed
      Rails.logger.warn("[MPWebhookDEBUG] x_signature=#{x_signature.inspect} " \
        "x_request_id=#{x_request_id.inspect} secret_len=#{secret.length} " \
        "header_keys=#{request.headers.env.keys.grep(/HTTP_X|SIGNATURE|REQUEST_ID/i).inspect} " \
        "query_data_id=#{params.dig(:data, :id).inspect} body_data_id=#{body.dig("data", "id").inspect}")

      return false unless x_signature.present? && x_request_id.present?

      parts = x_signature.split(",").each_with_object({}) do |part, h|
        k, v = part.split("=", 2)
        h[k.to_s.strip] = v.to_s.strip
      end

      ts = parts["ts"]
      v1 = parts["v1"]
      return false unless ts.present? && v1.present?

      # data.id comes from the parsed body — do NOT re-read the request body here
      data_id = body.dig("data", "id") || params.dig(:data, :id)
      manifest = "id:#{data_id};request-id:#{x_request_id};ts:#{ts};"
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)

      result = ActiveSupport::SecurityUtils.secure_compare(v1, expected)
      Rails.logger.warn("[MPWebhookDEBUG] manifest=#{manifest.inspect} " \
        "expected=#{expected} received_v1=#{v1} match=#{result}")
      result
    rescue StandardError => e
      Rails.logger.warn("[MPWebhookDEBUG] raised #{e.class}: #{e.message}")
      false
    end
  end
end
