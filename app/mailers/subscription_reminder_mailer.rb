class SubscriptionReminderMailer < ApplicationMailer
  def reminder(user, subscription, days_overdue)
    @user         = user
    @subscription = subscription
    @days_overdue = days_overdue
    @payment_url  = new_subscription_url(host: app_host, protocol: :https)

    mail(
      to:      user.email,
      subject: subject_for(days_overdue)
    )
  end

  private

  def subject_for(days_overdue)
    case days_overdue
    when 0 then "Tu pago está pendiente"
    when 2 then "Recordatorio: tu pago sigue pendiente"
    else        "⚠️ Último aviso: tu acceso se suspenderá mañana"
    end
  end

  def app_host
    host = Rails.application.credentials.dig(:app_host)
    raise "Missing credential: app_host — required for reminder mailer URLs" if host.blank?
    host
  end
end
