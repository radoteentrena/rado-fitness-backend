class Api::V1::UsersController < Api::V1::BaseController
  # PUT /api/v1/users/avatar
  def update_avatar
    if params[:avatar].blank?
      return render json: { error: "No se recibió ninguna imagen." }, status: :unprocessable_entity
    end

    current_user.avatar.attach(params[:avatar])

    if current_user.avatar.attached?
      render json: { avatar_url: url_for(current_user.avatar) }
    else
      render json: { errors: [ "No se pudo guardar la imagen." ] }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/users/progress
  def progress
    user = current_user

    completed_count = user.training_sessions.where(status: :completed).count
    streak          = calculate_streak(user)

    recent_sessions = user.training_sessions
      .includes(:workout)
      .where(status: [ TrainingSession.statuses[:completed], TrainingSession.statuses[:skipped] ])
      .order(session_number: :desc)
      .limit(10)
      .map do |s|
        {
          date:         (s.completed_at || s.skipped_at)&.to_date&.to_s,
          status:       s.status,
          workout_name: s.workout.name
        }
      end

    render json: {
      streak:             streak,
      days_trained:       completed_count,
      workout_compliance: user.workout_compliance_score.nil? ? user.calculate_workout_compliance_score : user.workout_compliance_score,
      metric_compliance:  user.diet_adherence_score.nil?     ? user.calculate_diet_adherence_score     : user.diet_adherence_score,
      recent_sessions:    recent_sessions
    }
  end

  private

  def calculate_streak(user)
    sessions = user.training_sessions
      .where(status: [ TrainingSession.statuses[:completed], TrainingSession.statuses[:skipped] ])
      .order(session_number: :desc)

    streak = 0
    sessions.each do |s|
      break if s.skipped?
      streak += 1
    end
    streak
  end
end
