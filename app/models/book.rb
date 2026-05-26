class Book < ApplicationRecord
  has_many :book_chunks, dependent: :destroy
  has_one_attached :pdf

  validates :title, presence: true

  enum :ingestion_status, { pending: 0, processing: 1, completed: 2, failed: 3 }, default: :pending
end
