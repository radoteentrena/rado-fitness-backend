class AddIndexMpPreferenceIdToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_index :subscriptions, :mp_preference_id,
              unique: true,
              where:  "mp_preference_id IS NOT NULL",
              name:   "index_subscriptions_on_mp_preference_id"
  end
end
