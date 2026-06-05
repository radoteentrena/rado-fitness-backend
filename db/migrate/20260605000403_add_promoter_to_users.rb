class AddPromoterToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :promoter, :boolean, default: false, null: false
  end
end
