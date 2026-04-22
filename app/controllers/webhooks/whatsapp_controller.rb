module Webhooks
  class WhatsappController < ApplicationController
    skip_before_action :verify_authenticity_token

    # NOTE: WhatsApp integration is sending-only, not receiving.
    # The incoming webhook endpoint is not actively used.
    # If receiving messages becomes a requirement, implement Whatsapp::IncomingMessage
    # to parse and process inbound messages from Twilio.
    def incoming
      twiml = Twilio::TwiML::MessagingResponse.new do |r|
        r.message body: "Echo: received"
      end

      render xml: twiml.to_s
    end
  end
end
