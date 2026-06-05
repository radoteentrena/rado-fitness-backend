class PromoConversion < ApplicationRecord
  belongs_to :promo_link
  belongs_to :referred_user, class_name: "User"
  belongs_to :subscription

  scope :pending, -> { where(paid_at: nil) }
  scope :paid,    -> { where.not(paid_at: nil) }
end
