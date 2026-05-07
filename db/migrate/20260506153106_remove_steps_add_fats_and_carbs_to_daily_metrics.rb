class RemoveStepsAddFatsAndCarbsToDailyMetrics < ActiveRecord::Migration[8.0]
  def change
    remove_column :daily_metrics, :steps, :integer
    add_column :daily_metrics, :fats, :integer
    add_column :daily_metrics, :carbs, :integer
  end
end
