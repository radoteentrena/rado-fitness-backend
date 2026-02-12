module Whatsapp
  class IncomingMessage
    attr_reader :params, :response_message

    def initialize(params)
      @params = params
      @response_message = ""
    end

    def process
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
        @response_message = "Recibido. Procesando con IA..."
        Rails.logger.info "✅ Webhook: DailyMetric created for #{user.name} (#{clean_phone})"
      else
        @response_message = "No te reconozco. Asegúrate de que tu número esté registrado."
        Rails.logger.warn "⚠️ Webhook: User not found for phone: #{clean_phone}. params[:From]: #{from_number}"
      end
    end
  end
end
