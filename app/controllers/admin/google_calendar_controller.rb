module Admin
  class GoogleCalendarController < ApplicationController
    def connect
      redirect_to GoogleCalendar::Auth.authorization_url, allow_other_host: true
    end

    def callback
      GoogleCalendar::Auth.exchange_code(params[:code])
      redirect_to admin_root_path, notice: "Google Calendar conectado correctamente."
    rescue StandardError => e
      redirect_to admin_root_path, alert: "Error al conectar Google Calendar: #{e.message}"
    end
  end
end
