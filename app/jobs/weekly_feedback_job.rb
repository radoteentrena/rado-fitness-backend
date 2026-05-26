class WeeklyFeedbackJob < ApplicationJob
  queue_as :default

  def perform
    User.active.find_each do |user|
      process_user(user)
    rescue StandardError => e
      Rails.logger.error("[WeeklyFeedbackJob] Failed for user #{user.id}: #{e.message}")
    end
  end

  private

  def process_user(user)
    stats = build_stats(user)

    WeeklyFeedbackMailer.summary(
      user,
      feedback_text:      generate_feedback(user, stats),
      workouts_this_week: stats[:workouts_this_week],
      diet_adherence:     stats[:diet_adherence],
      current_weight:     stats[:current_weight],
      week_number:        stats[:week_number]
    ).deliver_later
  end

  def build_stats(user)
    week_range = 6.days.ago.to_date..Date.current
    metrics    = user.daily_metrics.where(date_logged: week_range)

    logged_count    = metrics.where(compliant: true).count
    on_target_count = metrics.where(on_target: true).count
    diet_adherence  = logged_count.positive? ? (on_target_count.to_f / logged_count * 100).round : 0

    {
      workouts_this_week: metrics.where(workout_completed: true).count,
      diet_adherence:     diet_adherence,
      current_weight:     user.latest_weight || "—",
      week_number:        user.active_program&.current_week || 1
    }
  end

  def generate_feedback(user, stats)
    GeminiService.new.generate_weekly_feedback(
      name:          user.first_name,
      workouts:      stats[:workouts_this_week],
      diet_adherence: stats[:diet_adherence],
      weight:        stats[:current_weight],
      week:          stats[:week_number]
    )
  rescue StandardError => e
    Rails.logger.error("[WeeklyFeedbackJob] Gemini failed for user #{user.id}: #{e.message}")
    "Semana #{stats[:week_number]} registrada. Seguí el proceso."
  end
end
