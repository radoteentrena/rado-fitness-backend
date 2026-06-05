class CreatePromoLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :promo_links do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :code,   null: false
      t.string  :label,  null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :promo_links, :code, unique: true
  end
end
