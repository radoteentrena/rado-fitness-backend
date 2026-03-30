class AddGoogleOAuthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string, null: true
    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
    add_column :users, :provider, :string, default: 'email', null: false
  end
end
