class PhaseRoutine < ApplicationRecord
  belongs_to :phase
  belongs_to :routine

  before_validation :clone_routine_if_template_for_user_program

  private

  def clone_routine_if_template_for_user_program
    return unless phase&.program&.user_id && routine&.is_template?

    self.routine = routine.clone_to_user(phase.program.user)
  end
end
