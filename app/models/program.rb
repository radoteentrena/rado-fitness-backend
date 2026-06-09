class Program < ApplicationRecord
  belongs_to :user, optional: true
  has_many :phases, -> { order(order_index: :asc) }, dependent: :destroy
  has_many :routines, through: :phases
  has_many :user_dietary_plans, through: :phases
  has_many :training_sessions, dependent: :destroy
  has_many :ai_conversations, dependent: :nullify

  before_destroy :prevent_deletion_if_assigned_to_user

  def current_week
    user&.training_sessions
        &.where(program: self, status: [ TrainingSession.statuses[:pending], TrainingSession.statuses[:in_progress] ])
        &.order(created_at: :asc)
        &.first
        &.cycle_number || ((Date.current - created_at.to_date).to_i / 7) + 1
  end

  def current_routine
    week = current_week
    cumulative_weeks = 0

    routines.order(:id).find do |routine|
      duration = routine.duration_weeks || 4
      cumulative_weeks += duration
      week <= cumulative_weeks
    end || routines.last
  end

  def assign_to_user(target_user)
    transaction do
      new_program = dup
      new_program.user = target_user
      new_program.save!

      phases.each do |phase|
        new_phase = phase.dup
        new_phase.program = new_program
        new_phase.save!

        phase.routines.each do |routine|
          PhaseRoutine.create!(phase: new_phase, routine: routine)
        end
      end

      TrainingProgressionService.create_initial_session(target_user, new_program)

      new_program
    end
  end

  private

  def prevent_deletion_if_assigned_to_user
    if user_id.present?
      errors.add(:base, "Cannot delete a program assigned to a user. Unassign it first.")
      throw(:abort)
    end
  end
end
