class Program < ApplicationRecord
  belongs_to :user, optional: true # Optional if it's a template
  has_many :phases, -> { order(order_index: :asc) }, dependent: :destroy
  has_many :routines, through: :phases
  has_many :user_dietary_plans, through: :phases

  public

  def current_week
    ((Date.current - created_at.to_date).to_i / 7) + 1
  end

  def current_routine
    week = current_week
    cumulative_weeks = 0

    # Assuming routines are executed in order of ID
    routines.order(:id).find do |routine|
      duration = routine.duration_weeks || 4 # Default to 4 weeks if not specified
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

        phase.routines.templates.each do |routine|
          new_routine = routine.clone_to_user(target_user)
          new_routine.phase = new_phase
          new_routine.save!
        end
      end

      new_program
    end
  end
end
