class AddOnTargetToDailyMetrics < ActiveRecord::Migration[8.0]
  def change
    add_column :daily_metrics, :on_target, :boolean, default: false
  end
end
