class UserDietaryPlan < ApplicationRecord
  belongs_to :user
  belongs_to :dietary_plan, optional: true # The template source
  has_many :daily_metrics, dependent: :nullify

  scope :active, -> { where(active: true) }

  def average_calories
    daily_metrics.average(:calories_consumed).to_f.round
  end

  def average_weight
    daily_metrics.average(:weight).to_f.round(1)
  end

  def weight_progress
    return 0 unless daily_metrics.any?
    (daily_metrics.last.weight - daily_metrics.first.weight).round(1)
  end
end
