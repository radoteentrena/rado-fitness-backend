class PhaseRoutine < ApplicationRecord
  belongs_to :phase
  belongs_to :routine

  before_validation :clone_routine_if_template_for_user_program
  after_create :bootstrap_initial_session_if_needed

  private

  def clone_routine_if_template_for_user_program
    return unless phase&.program&.user_id && routine&.is_template?

    self.routine = routine.clone_to_user(phase.program.user)
  end

  def bootstrap_initial_session_if_needed
    program = phase.program
    return unless program.user_id

    user = program.user
    return if TrainingSession.where(user: user, program: program).exists?

    first_phase = program.phases.order(order_index: :asc).first
    return unless first_phase.id == phase.id

    TrainingProgressionService.create_initial_session(user, program)
  rescue ArgumentError => e
    Rails.logger.warn("[PhaseRoutine#bootstrap_initial_session] #{e.message}")
  end
end
