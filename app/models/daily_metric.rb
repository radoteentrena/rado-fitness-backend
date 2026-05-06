class DailyMetric < ApplicationRecord
  belongs_to :user
  belongs_to :user_dietary_plan, optional: true

  before_validation :assign_to_active_plan, on: :create
  before_save :parse_content_with_ai, if: :should_parse_ai?
  before_save :calculate_compliance
  after_save :check_weight_spike, if: :saved_change_to_weight?
  after_save :refresh_user_scores

  private

  def calculate_compliance
    self.compliant = (calories_consumed.to_i > 0 || protein_consumed.to_i > 0)
    
    c_target = user_dietary_plan&.calories_target
    p_target = user_dietary_plan&.protein_target

    if compliant && c_target.present? && p_target.present?
      c_range = (c_target * 0.9)..(c_target * 1.1)
      p_range = (p_target * 0.9)..(p_target * 1.1)

      self.on_target = c_range.cover?(calories_consumed) && p_range.cover?(protein_consumed)
    else
      self.on_target = false
    end
  end

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
    self.fats              ||= parsed_data["fats"]
    self.carbs             ||= parsed_data["carbs"]
    self.weight            ||= parsed_data["weight"]
  rescue => e
    Rails.logger.error("DailyMetric AI Parse Error: #{e.message}")
  end

  def check_weight_spike
    return unless weight.present?

    previous_weight = user.daily_metrics.where("date_logged < ?", date_logged).order(date_logged: :desc).pick(:weight)
    return unless previous_weight.present?

    weight_diff = weight - previous_weight
    if weight_diff > 2.0
      CoachAlert.create!(
        user: user,
        category: :weight_spike,
        message: "Weight Spike Detected: +#{weight_diff.round(1)}kg (prev: #{previous_weight}kg, now: #{weight}kg) on #{date_logged}",
        status: :pending
      )
    end
  end

  def refresh_user_scores
    user.refresh_compliance_scores!
  end
end
