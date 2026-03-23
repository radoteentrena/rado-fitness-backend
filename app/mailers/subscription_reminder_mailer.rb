class SubscriptionReminderMailer < ApplicationMailer
  def reminder(user, subscription, days_overdue)
    @user = user
    @subscription = subscription
    @days_overdue = days_overdue
    @payment_url = new_subscription_url

    subject = case days_overdue
              when 0 then "Tu pago está pendiente — Rado Fitness"
              when 2 then "Recordatorio: tu pago sigue pendiente — Rado Fitness"
              when 4 then "⚠️ Último aviso: tu acceso se suspenderá mañana — Rado Fitness"
              else        "Pago pendiente — Rado Fitness"
              end

    mail(to: @user.email, subject: subject)
  end
end
