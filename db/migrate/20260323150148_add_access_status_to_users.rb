class AddAccessStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :access_status, :integer, null: false, default: 0
  end
end
