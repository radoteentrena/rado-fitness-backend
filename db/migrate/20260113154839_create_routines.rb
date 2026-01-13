class CreateRoutines < ActiveRecord::Migration[8.0]
  def change
    create_table :routines do |t|
      t.string :name
      t.text :description
      t.references :user, null: true, foreign_key: true
      t.boolean :is_template, default: false

      t.timestamps
    end
  end
end
