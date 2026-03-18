module Webhooks
  class StripeController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
      webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)

      ProcessPaymentEventJob.perform_later(
        processor: "stripe",
        event_type: event.type,
        payload: event.data.object.to_h.deep_stringify_keys
      )

      head :ok
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.warn "Stripe webhook signature verification failed: #{e.message}"
      head :bad_request
    rescue JSON::ParserError => e
      Rails.logger.warn "Stripe webhook JSON parse error: #{e.message}"
      head :bad_request
    end
  end
end
