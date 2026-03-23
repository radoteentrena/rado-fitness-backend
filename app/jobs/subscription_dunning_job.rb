class SubscriptionDunningJob < ApplicationJob
  queue_as :default

  def perform
    process_one_time_expired
    process_recurring_past_due
  end

  private

  # One-time: status stays :active, check access_expires_at
  def process_one_time_expired
    Subscription.where(billing_type: :one_time, status: :active)
                .where("access_expires_at < ?", Time.current)
                .includes(:user)
                .find_each do |sub|
      days_overdue = (Date.current - sub.access_expires_at.to_date).to_i
      process_dunning(sub, days_overdue)
    end
  end

  # Recurring: check past_due status
  def process_recurring_past_due
    Subscription.where(billing_type: :recurring, status: :past_due)
                .where.not(past_due_since: nil)
                .includes(:user)
                .find_each do |sub|
      days_overdue = (Date.current - sub.past_due_since.to_date).to_i
      process_dunning(sub, days_overdue)
    end
  end

  def process_dunning(subscription, days_overdue)
    user = subscription.user

    case days_overdue
    when 0, 2, 4
      send_reminder(user, subscription, days_overdue) if should_send_reminder?(subscription)
    end

    if days_overdue >= 5
      user.access_locked! unless user.access_locked?

      # Cancel one-time subscriptions after locking
      if subscription.one_time? && subscription.active?
        subscription.update!(status: :canceled)
      end
    end
  end

  def should_send_reminder?(subscription)
    subscription.reminded_at.nil? || subscription.reminded_at.to_date < Date.current
  end

  def send_reminder(user, subscription, days_overdue)
    SubscriptionReminderMailer.reminder(user, subscription, days_overdue).deliver_later

    # WhatsApp reminders deferred — uncomment when WhatsApp outbound service is ready
    # Whatsapp::SendMessage.call(phone: user.phone, body: reminder_message(days_overdue))

    subscription.update!(reminded_at: Time.current)

    Rails.logger.info "Dunning reminder sent to user #{user.id} (day #{days_overdue})"
  end
end
