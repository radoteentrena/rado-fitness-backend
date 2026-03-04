class Book < ApplicationRecord
  has_many :book_chunks, dependent: :destroy

  validates :title, presence: true
end
