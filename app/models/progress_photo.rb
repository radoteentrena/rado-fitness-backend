class ProgressPhoto < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  validates :date, presence: true
  validate :image_must_be_attached

  private

  def image_must_be_attached
    errors.add(:image, "must be attached") unless image.attached?
  end
end
