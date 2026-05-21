class AddIndexToBookingsScheduledAt < ActiveRecord::Migration[8.0]
  def change
    add_index :bookings, :scheduled_at
  end
end
