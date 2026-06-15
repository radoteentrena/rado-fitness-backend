class ProgressPhoto < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  validates :date, presence: true
  validates :image,
            file_size: { less_than: 15.megabytes },
            file_content_type: { in: %w[image/png image/jpeg image/webp image/heic image/heif] },
            allow_nil: true
  validate :image_must_be_attached

  private

  def image_must_be_attached
    errors.add(:image, "must be attached") unless image.attached?
  end
end
