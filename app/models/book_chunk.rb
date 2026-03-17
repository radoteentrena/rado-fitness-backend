class BookChunk < ApplicationRecord
  belongs_to :book, counter_cache: :chunks_count

  has_neighbors :embedding

  validates :content, presence: true

  # Search for chunks most similar to a query embedding
  # Returns chunks ordered by cosine similarity (closest first)
  scope :search, ->(query_embedding, limit: 10) {
    nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(limit)
  }
end
