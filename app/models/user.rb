class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_secure_token :auth_token

  include Discard::Model

  enum :status, { lead: 0, active: 1, churned: 2, archived: 3 }, default: :lead
  enum :access_status, { active: 0, locked: 1 }, default: :active, prefix: :access
  enum :plan_tier, { basic: 0, medium: 1, high_ticket: 2 }
  enum :category, { pelele: 0, civil: 1, soldado: 2 }

  # Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :phone, presence: true, format: { with: /\A\+?[\d\s\-()]{7,20}\z/, message: "formato inválido" }

  # Scopes
  scope :leads, -> { where(status: :lead) }

  scope :with_workout_compliance, ->(level) {
    case level
    when "high"   then where("workout_compliance_score >= ?", 80)
    when "medium" then where("workout_compliance_score >= ? AND workout_compliance_score < ?", 50, 80)
    when "low"    then where("workout_compliance_score < ?", 50)
    end
  }

  scope :with_diet_adherence, ->(level) {
    case level
    when "high"   then where("diet_adherence_score >= ?", 80)
    when "medium" then where("diet_adherence_score >= ? AND diet_adherence_score < ?", 50, 80)
    when "low"    then where("diet_adherence_score < ?", 50)
    end
  }

  # Callbacks
  before_validation :set_temporary_password, on: :create
  before_validation :strip_whitespace

  # Associations
  has_one :onboarding_profile, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  accepts_nested_attributes_for :onboarding_profile
  has_many :coach_alerts, dependent: :destroy

  has_many :routines, dependent: :destroy
  has_many :programs, dependent: :destroy
  has_many :user_dietary_plans, dependent: :destroy
  has_many :daily_metrics, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :progress_photos, dependent: :destroy
  has_many :program_executions, dependent: :destroy
  has_many :training_sessions, dependent: :destroy

  def name
    "#{first_name} #{last_name}"
  end

  def active_subscription
    subscriptions.where(status: [:pending, :active]).order(created_at: :desc).first
  end

  def target_workouts_per_week
    return 4 unless programs.exists?

    active_routine = programs.last.routines.first
    return 4 unless active_routine

    days_count = active_routine.workouts.count
    days_count.positive? ? days_count : 4
  end

  # S% - Session Compliance (Workouts)
  # Based on the last 7 days vs Target
  def calculate_workout_compliance_score
    last_7_days_metrics = daily_metrics.where(date_logged: 6.days.ago.to_date..Date.today)
                                       .where(workout_completed: true)
                                       .count

    target = target_workouts_per_week
    return 0 if target.zero?

    ((last_7_days_metrics.to_f / target) * 100).clamp(0, 100).round
  end

  # M% - Metric Compliance (Diet Consistency)
  # Did they log at all? (Last 30 days)
  def calculate_diet_consistency_score
    last_30_days_count = daily_metrics.where(date_logged: 29.days.ago.to_date..Date.today)
                                      .where(compliant: true)
                                      .count

    (last_30_days_count.to_f / 30 * 100).round
  end

  # M% - Metric Adherence (Diet Accuracy)
  # Of the days they logged, how many were on target?
  def calculate_diet_adherence_score
    relevant_metrics = daily_metrics.where(date_logged: 29.days.ago.to_date..Date.today)
                                    .where(compliant: true)

    logged_count = relevant_metrics.count
    return 0 if logged_count.zero?

    on_target_count = relevant_metrics.where(on_target: true).count
    (on_target_count.to_f / logged_count * 100).round
  end

  def refresh_compliance_scores!
    update_columns(
      workout_compliance_score: calculate_workout_compliance_score,
      diet_adherence_score: calculate_diet_adherence_score
    )
  end

  def latest_weight
    daily_metrics.where.not(weight: nil).order(date_logged: :desc).pick(:weight).truncate(2) if daily_metrics.exists?
  end

  def weight_trend(days_ago = 7)
    current = latest_weight
    return nil unless current

    previous = daily_metrics.where("date_logged <= ?", days_ago.days.ago.to_date)
                            .where.not(weight: nil)
                            .order(date_logged: :desc)
                            .pick(:weight)

    return nil unless previous

    (current - previous).round(1)
  end

  def self.recent_growth_data(days = 7)
    data = where("created_at > ?", days.days.ago).group("DATE(created_at)").count
    (days.days.ago.to_date..Date.today).each { |date| data[date] ||= 0 }
    sorted_data = data.sort.to_h

    {
      categories: sorted_data.keys.map { |d| d.strftime("%d %b") },
      series: [ { name: "New Users", data: sorted_data.values } ]
    }
  end

  private

  def set_temporary_password
    self.password = SecureRandom.hex(8) if password.blank?
  end

  def strip_whitespace
    self.first_name = first_name&.strip
    self.last_name = last_name&.strip
    self.phone = phone&.strip
    self.email = email&.strip&.downcase
  end

end
