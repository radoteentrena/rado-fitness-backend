class PaymentReminderJob < ApplicationJob
  queue_as :default

  def perform
    window_start = 2.days.from_now.beginning_of_day
    window_end   = 2.days.from_now.end_of_day
    notified_user_ids = Set.new

    recurring_expiring(window_start, window_end).each do |sub|
      notify(sub.user, notified_user_ids)
    end

    one_time_expiring(window_start, window_end).each do |sub|
      notify(sub.user, notified_user_ids)
    end
  end

  private

  def recurring_expiring(from, to)
    Subscription.where(billing_type: :recurring)
                .where(current_period_end: from..to)
                .includes(:user)
  end

  def one_time_expiring(from, to)
    Subscription.where(billing_type: :one_time)
                .where(access_expires_at: from..to)
                .includes(:user)
  end

  def notify(user, notified_user_ids)
    return if user.fcm_token.blank?
    return if notified_user_ids.include?(user.id)

    PushNotification.new(
      user: user,
      title: "Tu acceso vence en 2 días",
      body: "Renovar ahora para no perder tu plan",
      data: { type: "payment_reminder" }
    ).deliver

    notified_user_ids.add(user.id)
  rescue StandardError => e
    Rails.logger.error("[PaymentReminderJob] Error for user #{user.id}: #{e.message}")
  end
end
