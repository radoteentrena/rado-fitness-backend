module Webhooks
  class WhatsappController < ApplicationController
    skip_before_action :verify_authenticity_token

    def incoming
      message = Whatsapp::IncomingMessage.new(params)
      message.process

      twiml = Twilio::TwiML::MessagingResponse.new do |r|
        r.message body: message.response_message
      end

      render xml: twiml.to_s
    end
  end
end
