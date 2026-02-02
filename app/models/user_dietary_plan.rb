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
    weights = daily_metrics.where.not(weight: nil).order(date_logged: :asc).pluck(:weight)
    return 0 if weights.empty?

    (weights.last - weights.first).round(1)
  end
end
