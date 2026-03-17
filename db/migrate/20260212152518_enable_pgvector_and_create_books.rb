class EnablePgvectorAndCreateBooks < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"

    create_table :books do |t|
      t.string :title, null: false
      t.string :author
      t.string :file_path
      t.integer :chunks_count, default: 0
      t.timestamps
    end

    create_table :book_chunks do |t|
      t.references :book, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :page_number
      t.integer :chunk_index
      t.vector :embedding, limit: 768
      t.timestamps
    end

    add_index :book_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
