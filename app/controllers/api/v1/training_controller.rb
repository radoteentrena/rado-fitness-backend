class Api::V1::TrainingController < Api::V1::BaseController
  before_action :set_current_session, only: [ :start, :complete, :skip ]

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

  # POST /api/v1/training/complete
  def complete
    result = TrainingProgressionService.complete_session(
      @training_session,
      complete_params[:exercise_logs] || [],
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
    params.permit(
      :notes,
      exercise_logs: [ :workout_exercise_id, actual_sets: [ :reps, :weight, :rpe ] ]
    )
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
      .joins(:program_execution)
      .where(workout_exercise_id: workout_exercise.id)
      .where(program_executions: { user_id: user.id })
      .order("program_executions.completed_at DESC")
      .first

    return nil unless log

    execution = log.program_execution
    {
      date: execution.completed_at&.to_date&.to_s,
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

  # History shape includes prescribed + actual exercise logs
  def serialize_history_session(session)
    program_execution = session.program_execution

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
      exercise_logs: serialize_exercise_logs_for_history(session.workout, program_execution)
    }
  end

  def serialize_exercise_logs_for_history(workout, program_execution)
    return [] if program_execution.nil?

    logs_by_we_id = program_execution.exercise_logs
      .includes(:workout_exercise)
      .index_by(&:workout_exercise_id)

    workout.workout_exercises.includes(:exercise).order(order_index: :asc).map do |we|
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
