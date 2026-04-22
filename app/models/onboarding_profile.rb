class OnboardingProfile < ApplicationRecord
  belongs_to :user

  # Sanitization
  before_validation :sanitize_fields

  # Presence
  validates :gender, :age, :weight, :height, presence: true
  validates :experience_level, :commitment_level, :training_frequency, :training_years, presence: true
  validates :injuries, :diet_quality, :activity_level, presence: true
  validates :sleep_hours, :social_media_consent, :referral_source, presence: true
  validates :country, presence: true

  # Format & Range
  validates :age, numericality: { only_integer: true, greater_than: 13, less_than: 100 }
  validates :experience_level, numericality: { only_integer: true, in: 1..10 }
  validates :gender, inclusion: { in: %w[Masculino Femenino Otro] }
  validates :commitment_level, inclusion: { in: %w[Alto Moderado Bajo] }
  validates :training_frequency, inclusion: { in: ["2", "3", "4", "+4 veces"] }
  validates :training_years, inclusion: { in: ["0-1", "1-2", "2-5", "5+"] }
  validates :diet_quality, inclusion: { in: %w[Malos Regular Bueno Pro] }
  validates :activity_level, inclusion: { in: ["Sentado", "Levemente activo", "Activo", "Muy activo"] }
  validates :sleep_hours, inclusion: { in: %w[<4 4-6 6-8 8-10 +10] }
  validates :social_media_consent, inclusion: { in: %w[Si No] }
  validates :plays_sports, inclusion: { in: %w[Si No] }, allow_blank: true
  validates :referral_source, inclusion: { in: ["Redes sociales", "Publicidad", "Referencia", "Cercanía", "Otro"] }
  validates :referral_source_other, presence: true, if: -> { referral_source == "Otro" }
  validates :instagram, length: { maximum: 50 }, allow_blank: true
  validates :weight, length: { maximum: 20 }
  validates :height, length: { maximum: 20 }

  def argentina?
    country == "AR"
  end

  private

  def sanitize_fields
    self.instagram = instagram&.strip&.delete("@")
    self.weight = weight&.strip
    self.height = height&.strip
    self.best_lifts = best_lifts&.strip
    self.injuries = injuries&.strip
    self.sport_details = sport_details&.strip
    self.time_per_session = time_per_session&.strip
    self.goals_other = goals_other&.strip
    self.referral_source_other = referral_source_other&.strip
  end
end
