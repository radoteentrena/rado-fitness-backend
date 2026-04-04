class DropLeadsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :leads, if_exists: true
  end
end
