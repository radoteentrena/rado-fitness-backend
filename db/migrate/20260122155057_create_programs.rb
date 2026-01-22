class CreatePrograms < ActiveRecord::Migration[8.0]
  def change
    create_table :programs do |t|
      t.string :name
      t.integer :duration_weeks
      t.text :description
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
