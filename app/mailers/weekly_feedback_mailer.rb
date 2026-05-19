class WeeklyFeedbackMailer < ApplicationMailer
  def summary(user, feedback_text:, workouts_this_week:, diet_adherence:, current_weight:, week_number:)
    @user               = user
    @feedback_text      = feedback_text
    @workouts_this_week = workouts_this_week
    @diet_adherence     = diet_adherence
    @current_weight     = current_weight
    @week_number        = week_number
    @dashboard_url      = root_url(host: app_host, protocol: :https)
    mail(
      to:      user.email,
      subject: "Tu resumen semanal — Semana #{week_number}"
    )
  end

  private

  def app_host
    host = Rails.application.credentials.dig(:app_host)
    raise "Missing credential: app_host — required for weekly feedback mailer URLs" if host.blank?
    host
  end
end
