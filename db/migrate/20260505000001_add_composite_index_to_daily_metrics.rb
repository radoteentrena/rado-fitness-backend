class AddCompositeIndexToDailyMetrics < ActiveRecord::Migration[8.0]
  def change
    add_index :daily_metrics, [:user_id, :date_logged], name: "index_daily_metrics_on_user_id_and_date_logged"
  end
end
