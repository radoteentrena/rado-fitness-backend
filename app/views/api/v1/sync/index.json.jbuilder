json.user do
  json.extract! @user, :id, :first_name, :last_name, :email, :plan_tier, :category
  json.full_name @user.name
  json.avatar_url @user.avatar.attached? ? url_for(@user.avatar) : nil
end

if @active_program
  json.active_program do
    json.extract! @active_program, :id, :name
  end
else
  json.active_program nil
end

json.recent_metrics @metrics

if @dietary_plan
  json.dietary_plan do
    json.extract! @dietary_plan, :id, :dietary_plan_id, :calories_target, :protein_target, :fats_target, :carbs_target, :notes, :start_date, :end_date, :active
    json.logged_weight @user.daily_metrics.exists?(date_logged: Date.today, weight: ..Float::INFINITY)
  end
else
  json.dietary_plan nil
end


if @next_session
  json.next_session do
    json.session_id @next_session.id
    json.status @next_session.status
    json.workout_id @next_session.workout_id
    json.workout_name @next_session.workout.name
    json.cycle_number @next_session.cycle_number
    json.day_number @next_session.workout.day_number
  end
else
  json.next_session nil
end

json.current_week_workouts do
  if @current_week_workouts.any?
    json.array! @current_week_workouts do |workout|
      json.extract! workout, :id, :name, :description, :day_number, :order_index

      json.exercises workout.workout_exercises.order(:order_index) do |workout_exercise|
        json.extract! workout_exercise, :id, :sets, :reps, :load, :intensity_technique, :sub_option_one, :sub_option_two

        json.exercise do
          json.extract! workout_exercise.exercise, :id, :name, :muscle_group, :video_link, :description
        end
      end
    end
  else
    json.array! []
  end
end
