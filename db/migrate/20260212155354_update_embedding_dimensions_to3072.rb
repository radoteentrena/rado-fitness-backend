class UpdateEmbeddingDimensionsTo3072 < ActiveRecord::Migration[8.0]
  def change
    remove_index :book_chunks, :embedding if index_exists?(:book_chunks, :embedding)
    change_column :book_chunks, :embedding, :vector, limit: 768
    add_index :book_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
