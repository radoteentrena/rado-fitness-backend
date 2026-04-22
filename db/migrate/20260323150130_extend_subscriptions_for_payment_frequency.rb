class ExtendSubscriptionsForPaymentFrequency < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :billing_type, :integer, null: false, default: 0
    add_column :subscriptions, :frequency, :integer, null: false, default: 0
    add_column :subscriptions, :access_expires_at, :datetime
    add_column :subscriptions, :reminded_at, :datetime
    add_column :subscriptions, :past_due_since, :datetime
    add_column :subscriptions, :mp_preference_id, :string
  end
end
