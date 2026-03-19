class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer  :processor,            null: false
      t.integer  :plan_tier,            null: false
      t.integer  :status,               null: false, default: 0
      t.string   :external_id
      t.string   :external_customer_id
      t.string   :external_plan_id
      t.string   :currency,             default: "USD"
      t.integer  :amount_cents
      t.datetime :current_period_end
      t.boolean  :cancel_at_period_end, default: false, null: false
      t.datetime :canceled_at

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :processor
  end
end
