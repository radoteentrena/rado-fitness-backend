class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.datetime   :scheduled_at, null: false
      t.string     :google_event_id
      t.string     :meet_link
      t.integer    :status, null: false, default: 0
      t.timestamps
    end
  end
end
