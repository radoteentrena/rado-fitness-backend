class AddIngestionStatusToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :ingestion_status, :integer, default: 0, null: false
  end
end
