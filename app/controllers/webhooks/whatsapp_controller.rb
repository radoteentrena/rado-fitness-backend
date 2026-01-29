module Webhooks
  class WhatsappController < ApplicationController
    skip_before_action :verify_authenticity_token

    def incoming
      from_number = params[:From]
      body = params[:Body]

      clean_phone = from_number&.gsub("whatsapp:", "")

      user = User.find_by(phone: clean_phone)

      if user
        DailyMetric.create!(
          user: user,
          date_logged: Date.current,
          raw_message_content: body
        )
        response_message = "Recibido. Procesando con IA..."
        Rails.logger.info "✅ Webhook: DailyMetric created for #{user.name} (#{clean_phone})"
      else
        response_message = "No te reconozco. Asegúrate de que tu número esté registrado."
        Rails.logger.warn "⚠️ Webhook: User not found for phone: #{clean_phone}. params[:From]: #{from_number}"
      end

      twiml = Twilio::TwiML::MessagingResponse.new do |r|
        r.message body: response_message
      end

      render xml: twiml.to_s
    end
  end
end
