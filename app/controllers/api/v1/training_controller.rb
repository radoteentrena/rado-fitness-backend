class Api::V1::TrainingController < Api::V1::BaseController
  before_action :set_current_session, only: [ :start, :log_exercise, :complete, :skip ]

  # GET /api/v1/training/current
  def current
    session = TrainingSession.current_for(current_user)

    if session.nil?
      render json: { session: nil, status: "no_active_program" }
    else
      render json: { session: serialize_full_session(session) }
    end
  end

  # POST /api/v1/training/start
  def start
    result = TrainingProgressionService.start_session(@training_session)
    render json: { session: serialize_full_session(result) }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PUT /api/v1/training/log_exercise
  def log_exercise
    we_id = log_exercise_params[:workout_exercise_id]
    sets  = log_exercise_params[:actual_sets]

    unless we_id.present?
      return render json: { error: "workout_exercise_id es requerido." }, status: :unprocessable_entity
    end

    log = ExerciseLog.find_or_initialize_by(
      training_session: @training_session,
      workout_exercise_id: we_id
    )
    log.actual_sets = sets

    if log.save
      render json: { exercise_log: { workout_exercise_id: log.workout_exercise_id, actual_sets: log.actual_sets } }
    else
      render json: { error: log.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/training/complete
  def complete
    result = TrainingProgressionService.complete_session(
      @training_session,
      notes: complete_params[:notes]
    )

    render json: {
      session: serialize_summary_session(result[:session]),
      next_session: result[:next_session] ? serialize_summary_session(result[:next_session]) : nil
    }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/training/skip
  def skip
    result = TrainingProgressionService.skip_session(
      @training_session,
      reason: params.dig(:training_session, :reason) || params[:reason]
    )

    render json: {
      session: serialize_summary_session(result[:session]),
      next_session: result[:next_session] ? serialize_summary_session(result[:next_session]) : nil
    }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/training/history
  def history
    page     = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 20).to_i.clamp(1, 100)

    sessions = current_user.training_sessions
      .where(status: [ TrainingSession.statuses[:completed], TrainingSession.statuses[:skipped] ])
      .order(session_number: :desc)

    total_count = sessions.count
    total_pages = (total_count.to_f / per_page).ceil
    paginated = sessions.offset((page - 1) * per_page).limit(per_page)

    render json: {
      sessions: paginated.map { |s| serialize_history_session(s) },
      meta: {
        current_page: page,
        total_pages: total_pages,
        total_count: total_count
      }
    }
  end

  private

  def set_current_session
    @training_session = TrainingSession.current_for(current_user)

    if @training_session.nil?
      render json: { error: "No hay sesión activa." }, status: :not_found
    end
  end

  def complete_params
    params.permit(:notes)
  end

  def log_exercise_params
    params.permit(:workout_exercise_id, actual_sets: [ :reps, :weight, :rpe ])
  end

  # Full session shape including workout exercises and last_logged data
  def serialize_full_session(session)
    {
      id: session.id,
      session_number: session.session_number,
      status: session.status,
      phase_name: session.phase.name,
      cycle_number: session.cycle_number,
      workout: serialize_workout_with_history(session.workout, session.user)
    }
  end

  def serialize_workout_with_history(workout, user)
    {
      id: workout.id,
      name: workout.name,
      day_number: workout.day_number,
      exercises: workout.workout_exercises.includes(:exercise).order(order_index: :asc).map do |we|
        {
          workout_exercise_id: we.id,
          exercise_name: we.exercise.name,
          muscle_group: we.exercise.muscle_group,
          sets: we.sets,
          reps: we.reps,
          load: we.load,
          early_rpe: we.early_rpe,
          last_rpe: we.last_rpe,
          last_logged: last_logged_for(we, user)
        }
      end
    }
  end

  def last_logged_for(workout_exercise, user)
    log = ExerciseLog
      .joins(:training_session)
      .where(workout_exercise_id: workout_exercise.id)
      .where(training_sessions: { user_id: user.id, status: TrainingSession.statuses[:completed] })
      .order("training_sessions.completed_at DESC")
      .first

    return nil unless log

    {
      date: log.training_session.completed_at&.to_date&.to_s,
      actual_sets: log.actual_sets
    }
  end

  # Summary shape (no exercise detail) for next_session responses
  def serialize_summary_session(session)
    return nil if session.nil?

    {
      id: session.id,
      session_number: session.session_number,
      status: session.status,
      phase_name: session.phase.name,
      cycle_number: session.cycle_number,
      workout_name: session.workout.name
    }
  end

  def serialize_history_session(session)
    {
      id: session.id,
      session_number: session.session_number,
      status: session.status,
      phase_name: session.phase.name,
      workout_name: session.workout.name,
      started_at: session.started_at&.iso8601,
      completed_at: session.completed_at&.iso8601,
      skipped_at: session.skipped_at&.iso8601,
      skip_reason: session.skip_reason,
      notes: session.notes,
      exercise_logs: serialize_exercise_logs_for_history(session)
    }
  end

  def serialize_exercise_logs_for_history(session)
    logs_by_we_id = session.exercise_logs
      .includes(:workout_exercise)
      .index_by(&:workout_exercise_id)

    session.workout.workout_exercises.includes(:exercise).order(order_index: :asc).map do |we|
      log = logs_by_we_id[we.id]
      {
        exercise_name: we.exercise.name,
        prescribed: {
          sets: we.sets,
          reps: we.reps,
          load: we.load
        },
        actual_sets: log&.actual_sets
      }
    end
  end
end
