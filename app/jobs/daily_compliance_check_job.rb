class DailyComplianceCheckJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 2, wait: :polynomially_longer

  LOW_COMPLIANCE_THRESHOLD = 50
  INACTIVITY_DAYS          = 3

  def perform
    User.active.find_each do |user|
      check_inactivity(user)
      check_low_compliance(user)
    rescue StandardError => e
      Rails.logger.error("[DailyComplianceCheckJob] Error checking user #{user.id}: #{e.message}")
    end
  end

  private

  def check_inactivity(user)
    last_log = user.daily_metrics.maximum(:date_logged)
    return if last_log.nil?
    return if last_log >= INACTIVITY_DAYS.days.ago.to_date

    days_since = (Date.today - last_log).to_i
    return if alert_exists?(user, :missed_workout, since: INACTIVITY_DAYS.days.ago)

    CoachAlert.create!(
      user:     user,
      category: :missed_workout,
      message:  "No ha registrado métricas en #{days_since} días (último: #{last_log})",
      status:   :pending
    )
  end

  def check_low_compliance(user)
    score = user.diet_adherence_score.to_i
    return if score >= LOW_COMPLIANCE_THRESHOLD
    return if score.zero?
    return if alert_exists?(user, :low_compliance, since: 7.days.ago)

    CoachAlert.create!(
      user:     user,
      category: :low_compliance,
      message:  "Adherencia a la dieta #{score}% (últimos 30 días) — por debajo del umbral #{LOW_COMPLIANCE_THRESHOLD}%",
      status:   :pending
    )
  end

  def alert_exists?(user, category, since:)
    CoachAlert.where(user: user, category: category)
              .where("created_at >= ?", since)
              .exists?
  end
end
