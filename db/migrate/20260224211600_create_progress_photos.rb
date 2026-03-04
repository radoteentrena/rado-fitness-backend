class CreateProgressPhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :progress_photos do |t|
      t.references :user, null: false, foreign_key: true
      t.text :note
      t.date :date

      t.timestamps
    end
  end
end
