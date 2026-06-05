class CreatePromoConversions < ActiveRecord::Migration[8.0]
  def change
    create_table :promo_conversions do |t|
      t.references :promo_link,    null: false, foreign_key: true
      t.references :referred_user, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.references :subscription,  null: false, foreign_key: true
      t.string  :plan_tier,               null: false
      t.string  :currency,                null: false
      t.integer :full_price_cents,        null: false
      t.integer :paid_amount_cents,       null: false
      t.integer :promoter_earnings_cents, null: false
      t.datetime :paid_at
      t.timestamps
    end
  end
end
