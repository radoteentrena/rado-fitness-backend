class DailyMetric < ApplicationRecord
  belongs_to :user
  belongs_to :user_dietary_plan, optional: true

  before_validation :assign_to_active_plan, on: :create
  before_save :parse_content_with_ai, if: :should_parse_ai?

  private

  def assign_to_active_plan
    self.user_dietary_plan ||= user.user_dietary_plans.active.last
  end

  def should_parse_ai?
    raw_message_content.present? && (raw_message_content_changed? || ai_parsed_json.blank?)
  end

  def parse_content_with_ai
    return unless defined?(GeminiService)

    service = GeminiService.new
    parsed_data = service.parse_metrics(raw_message_content)

    return if parsed_data.blank?

    self.ai_parsed_json = parsed_data

    self.calories_consumed ||= parsed_data["calories"]
    self.protein_consumed  ||= parsed_data["protein"]
    self.steps             ||= parsed_data["steps"]
    self.weight            ||= parsed_data["weight"]
  rescue => e
    Rails.logger.error("DailyMetric AI Parse Error: #{e.message}")
  end
end
