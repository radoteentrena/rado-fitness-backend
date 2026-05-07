class AddPaymentLinkTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :payment_link_token, :string
    add_column :users, :payment_link_expires_at, :datetime
    add_index :users, :payment_link_token, unique: true
  end
end
