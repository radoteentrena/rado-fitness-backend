json.metrics @metrics do |metric|
  json.extract! metric, :id, :date_logged, :weight, :calories_consumed, :protein_consumed, :fats, :carbs, :workout_completed, :compliant, :on_target
end

json.meta do
  json.month @month
end
