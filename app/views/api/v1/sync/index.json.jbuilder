json.user do
  json.extract! @user, :id, :first_name, :last_name, :email, :plan_tier, :category
  json.full_name @user.name
end

json.recent_metrics @metrics

if @dietary_plan
  json.dietary_plan do
    json.extract! @dietary_plan, :id, :calories_target, :protein_target, :notes, :start_date, :end_date, :active
  end
else
  json.dietary_plan nil
end

if @active_program
  json.active_program do
    json.extract! @active_program, :id, :name, :duration_weeks
    json.current_week @current_week
  end
else
  json.active_program nil
end

if @active_routine
  json.active_routine do
    json.extract! @active_routine, :id, :name, :duration_weeks
  end
else
  json.active_routine nil
end

json.current_week_workouts do
  if @current_week_workouts.any?
    json.array! @current_week_workouts do |workout|
      json.extract! workout, :id, :name, :description, :day_number, :order_index

      json.exercises workout.workout_exercises.order(:order_index) do |workout_exercise|
        json.extract! workout_exercise, :id, :sets, :reps, :load, :sub_option_one, :sub_option_two

        json.exercise do
          json.extract! workout_exercise.exercise, :id, :name, :muscle_group, :video_link, :description
        end
      end
    end
  else
    json.array! []
  end
end
