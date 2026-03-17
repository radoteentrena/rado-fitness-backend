class AddLastSyncedAtToPrograms < ActiveRecord::Migration[8.0]
  def change
    add_column :programs, :last_synced_at, :datetime
  end
end
