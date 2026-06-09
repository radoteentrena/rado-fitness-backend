class Workout < ApplicationRecord
  belongs_to :routine
  has_many :workout_exercises, dependent: :destroy

  validates :name, presence: true

  after_create :bootstrap_initial_session_if_needed

  private

  def bootstrap_initial_session_if_needed
    routine.phase_routines.each do |pr|
      program = pr.phase.program
      next unless program.user_id
      next if TrainingSession.where(user_id: program.user_id, program: program).exists?

      first_phase = program.phases.order(order_index: :asc).first
      next unless first_phase.id == pr.phase.id

      TrainingProgressionService.create_initial_session(program.user, program)
    rescue ArgumentError
      next
    end
  end
end
