class TrainingProgressionService
  # Validates a program+phase combo and returns the primary routine or raises.
  # Primary routine = lowest order_index in phase_routines for that phase.
  def self.create_initial_session(user, program)
    validate_program!(program)

    first_phase = program.phases.order(order_index: :asc).first
    validate_phase!(first_phase)

    primary_routine = primary_routine_for_phase(first_phase)
    first_workout = primary_routine.workouts.order(order_index: :asc).first

    TrainingSession.create!(
      user: user,
      program: program,
      phase: first_phase,
      routine: primary_routine,
      workout: first_workout,
      cycle_number: 1,
      session_number: 1,
      status: :pending
    )
  end

  def self.start_session(training_session)
    unless training_session.pending? || training_session.in_progress?
      raise ArgumentError, "La sesión no está en estado pendiente (estado actual: #{training_session.status})"
    end

    reconcile_stale_routine!(training_session)

    return training_session if training_session.in_progress?

    training_session.update!(
      status: :in_progress,
      started_at: Time.current
    )
    training_session
  end

  def self.complete_session(training_session, notes: nil)
    unless training_session.in_progress?
      raise ArgumentError, "La sesión debe estar en progreso para completarse (estado actual: #{training_session.status})"
    end

    next_session = nil

    ActiveRecord::Base.transaction do
      training_session.update!(
        status: :completed,
        completed_at: Time.current,
        notes: notes
      )

      next_session = advance_progression(training_session)
    end

    { session: training_session, next_session: next_session }
  end

  def self.skip_session(training_session, reason: nil)
    unless training_session.pending? || training_session.in_progress?
      raise ArgumentError, "Solo se pueden saltar sesiones pendientes o en progreso (estado actual: #{training_session.status})"
    end

    next_session = nil

    ActiveRecord::Base.transaction do
      training_session.update!(
        status: :skipped,
        skipped_at: Time.current,
        skip_reason: reason
      )

      next_session = advance_progression(training_session)
    end

    { session: training_session, next_session: next_session }
  end

  # -------------------------------------------------------------------------
  private
  # -------------------------------------------------------------------------

  def self.validate_program!(program)
    unless program.phases.exists?
      raise ArgumentError, "El programa '#{program.name}' no tiene fases configuradas."
    end
  end

  def self.validate_phase!(phase)
    unless phase.duration_weeks.present? && phase.duration_weeks.is_a?(Integer) && phase.duration_weeks > 0
      raise ArgumentError, "La fase '#{phase.name}' no tiene duration_weeks configurado como entero positivo."
    end

    phase_routine = phase.phase_routines.order(order_index: :asc).first
    unless phase_routine
      raise ArgumentError, "La fase '#{phase.name}' no tiene rutinas asignadas."
    end

    routine = phase_routine.routine
    unless routine.workouts.exists?
      raise ArgumentError, "La rutina '#{routine.name}' no tiene entrenamientos (workouts) configurados."
    end
  end

  def self.primary_routine_for_phase(phase)
    phase_routine = phase.phase_routines.order(order_index: :asc).first
    raise ArgumentError, "La fase '#{phase.name}' no tiene rutinas asignadas." unless phase_routine

    phase_routine.routine
  end

  def self.advance_progression(completed_or_skipped_session)
    user = completed_or_skipped_session.user
    program = completed_or_skipped_session.program
    phase = completed_or_skipped_session.phase
    current_workout = completed_or_skipped_session.workout
    current_cycle = completed_or_skipped_session.cycle_number

    # Re-resolve the primary routine from the phase rather than trusting the
    # reference frozen on the session — guards against stale routine_id when
    # a routine is reassigned after sessions have been created.
    routine = primary_routine_for_phase(phase)

    ordered_workouts = routine.workouts.order(order_index: :asc).to_a
    current_index = ordered_workouts.index { |w| w.id == current_workout.id }

    next_session_number = next_session_number_for(user)

    # Case 1: Next workout exists in the same routine cycle
    if current_index && current_index + 1 < ordered_workouts.length
      next_workout = ordered_workouts[current_index + 1]
      return TrainingSession.create!(
        user: user,
        program: program,
        phase: phase,
        routine: routine,
        workout: next_workout,
        cycle_number: current_cycle,
        session_number: next_session_number,
        status: :pending
      )
    end

    # Case 2: End of routine — check phase completion before cycling
    next_cycle = current_cycle + 1

    completed_count = TrainingSession
      .where(user: user, phase: phase, status: :completed)
      .count

    workouts_per_routine = ordered_workouts.length
    total_sessions_in_phase = phase.duration_weeks * workouts_per_routine

    if completed_count >= total_sessions_in_phase
      return advance_to_next_phase(user, program, phase)
    end

    # Cycle back to the first workout of the same routine
    first_workout = ordered_workouts.first
    TrainingSession.create!(
      user: user,
      program: program,
      phase: phase,
      routine: routine,
      workout: first_workout,
      cycle_number: next_cycle,
      session_number: next_session_number,
      status: :pending
    )
  end

  def self.advance_to_next_phase(user, program, current_phase)
    current_order = current_phase.order_index

    next_phase = program.phases
      .where("order_index > ?", current_order)
      .order(order_index: :asc)
      .first

    unless next_phase
      CoachAlert.create!(
        user: user,
        category: :program_complete,
        status: :pending,
        message: "#{user.name} ha completado el programa #{program.name}"
      )
      return nil
    end

    validate_phase!(next_phase)

    primary_routine = primary_routine_for_phase(next_phase)
    first_workout = primary_routine.workouts.order(order_index: :asc).first
    next_session_number = next_session_number_for(user)

    TrainingSession.create!(
      user: user,
      program: program,
      phase: next_phase,
      routine: primary_routine,
      workout: first_workout,
      cycle_number: 1,
      session_number: next_session_number,
      status: :pending
    )
  end

  def self.reconcile_stale_routine!(training_session)
    current_primary = primary_routine_for_phase(training_session.phase)
    return if training_session.routine_id == current_primary.id

    first_workout = current_primary.workouts.order(order_index: :asc).first
    training_session.update!(routine: current_primary, workout: first_workout)
  end

  def self.next_session_number_for(user)
    last_number = TrainingSession.where(user: user).maximum(:session_number) || 0
    last_number + 1
  end
end
