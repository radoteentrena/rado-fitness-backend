class UserAlertJob < ApplicationJob
  queue_as :default

  def perform
    # Focus on 'soldado' or 'civil' users who should be active
    active_users = User.where(status: :active, category: [:soldado, :civil])

    active_users.find_each do |user|
      check_missed_workout(user)
    end
  end

  private

  def check_missed_workout(user)
    # Check if they have logged a workout in the last 3 days
    last_workout = user.daily_metrics.where(workout_completed: true).order(date_logged: :desc).first

    # If no workout ever, or last one was > 3 days ago
    if last_workout.nil? || last_workout.date_logged < 3.days.ago.to_date
      # Prevent duplicate pending alerts for the same category
      return if user.coach_alerts.pending.where(category: :missed_workout).exists?

      days_dry = last_workout ? (Date.today - last_workout.date_logged).to_i : "infinity"

      CoachAlert.create!(
        user: user,
        category: :missed_workout,
        message: "Missed Workout Alert: User has not logged a workout for #{days_dry} days.",
        status: :pending
      )
    end
  end
end
