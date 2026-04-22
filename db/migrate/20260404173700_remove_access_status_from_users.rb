class RemoveAccessStatusFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :access_status, :integer, if_exists: true
  end
end
