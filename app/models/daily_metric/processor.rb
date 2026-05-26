class DailyMetric
  class Processor
    def initialize(metric)
      @metric = metric
    end

    # Called from before_save
    def run
      parse_with_ai if should_parse_ai?
      calculate_compliance
    end

    # Called from after_save
    def run_after_save
      check_weight_spike if @metric.saved_change_to_weight?
      refresh_user_scores
    end

    private

    def should_parse_ai?
      @metric.raw_message_content.present? &&
        (@metric.raw_message_content_changed? || @metric.ai_parsed_json.blank?)
    end

    def parse_with_ai
      return unless defined?(GeminiService)

      parsed_data = GeminiService.new.parse_metrics(@metric.raw_message_content)
      return if parsed_data.blank?

      @metric.ai_parsed_json      = parsed_data
      @metric.calories_consumed ||= parsed_data["calories"]
      @metric.protein_consumed  ||= parsed_data["protein"]
      @metric.fats              ||= parsed_data["fats"]
      @metric.carbs             ||= parsed_data["carbs"]
      @metric.weight            ||= parsed_data["weight"]
    rescue StandardError => e
      Rails.logger.error("[DailyMetric::Processor] AI parse error for metric #{@metric.id}: #{e.message}")
      Sentry.capture_exception(e)
    end

    def calculate_compliance
      @metric.compliant = (@metric.calories_consumed.to_i > 0 || @metric.protein_consumed.to_i > 0)

      plan = @metric.user_dietary_plan
      if @metric.compliant && plan&.calories_target.present? && plan&.protein_target.present?
        c_range = (plan.calories_target * 0.9)..(plan.calories_target * 1.1)
        p_range = (plan.protein_target * 0.9)..(plan.protein_target * 1.1)
        @metric.on_target = c_range.cover?(@metric.calories_consumed) &&
                            p_range.cover?(@metric.protein_consumed)
      else
        @metric.on_target = false
      end
    end

    def check_weight_spike
      return unless @metric.weight.present?

      previous_weight = @metric.user.daily_metrics
        .where("date_logged < ?", @metric.date_logged)
        .order(date_logged: :desc)
        .pick(:weight)
      return unless previous_weight.present?

      diff = @metric.weight - previous_weight
      return unless diff > 2.0

      CoachAlert.create!(
        user:     @metric.user,
        category: :weight_spike,
        message:  "Weight Spike Detected: +#{diff.round(1)}kg (prev: #{previous_weight}kg, now: #{@metric.weight}kg) on #{@metric.date_logged}",
        status:   :pending
      )
    rescue StandardError => e
      Rails.logger.error("[DailyMetric::Processor] Weight spike check error for metric #{@metric.id}: #{e.message}")
    end

    def refresh_user_scores
      @metric.user.refresh_compliance_scores!
    rescue StandardError => e
      Rails.logger.error("[DailyMetric::Processor] Score refresh error for user #{@metric.user_id}: #{e.message}")
    end
  end
end
