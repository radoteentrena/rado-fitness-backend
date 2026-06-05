class PromoLink < ApplicationRecord
  belongs_to :user
  has_many :promo_conversions, dependent: :destroy

  validates :label, presence: true
  validates :code, presence: true, uniqueness: true

  before_validation :generate_code, on: :create

  scope :active, -> { where(active: true) }

  def full_url
    Rails.application.routes.url_helpers.new_onboarding_url(
      promo: code,
      host: Rails.application.credentials.dig(:app_host) || "localhost:3000",
      protocol: :https
    )
  end

  def pending_earnings_cents
    promo_conversions.pending.sum(:promoter_earnings_cents)
  end

  def total_earnings_cents
    promo_conversions.sum(:promoter_earnings_cents)
  end

  private

  def generate_code
    loop do
      self.code = SecureRandom.alphanumeric(8).upcase
      break unless PromoLink.exists?(code: code)
    end
  end
end
