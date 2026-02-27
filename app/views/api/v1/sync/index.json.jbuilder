json.user do
  json.extract! @user, :id, :first_name, :last_name, :email, :plan_tier, :category
  json.full_name @user.name
end

json.recent_metrics @metrics

if @active_program
  json.active_program do
    json.extract! @active_program, :id, :title, :duration_weeks
  end
else
  json.active_program nil
end

if @active_routine
  json.active_routine do
    json.extract! @active_routine, :id, :title, :duration_weeks
  end
else
  json.active_routine nil
end

json.current_week_workouts do
  if @current_week_workouts.is_a?(Hash)
    json.array! @current_week_workouts.keys.sort do |day_number|
      exercises_for_day = @current_week_workouts[day_number]

      json.day_number day_number
      # Infer workout name. For MVP we are grouping by day number.
      json.workout_name "Day #{day_number}"

      json.exercises exercises_for_day do |routine_exercise|
        json.extract! routine_exercise, :id, :sets, :reps, :load, :sub_option_one, :sub_option_two

        json.exercise do
          json.extract! routine_exercise.exercise, :id, :name, :muscle_group, :video_link, :description
        end
      end
    end
  else
    json.array! []
  end
end
