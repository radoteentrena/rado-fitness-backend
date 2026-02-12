class Program < ApplicationRecord
  belongs_to :user, optional: true # Optional if it's a template
  has_many :routines, dependent: :nullify

  after_create_commit :provision_google_sheet, if: -> { user.present? }

  private

  def provision_google_sheet
    ProvisionProgramSheetJob.perform_later(id)
  end

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

      routines.templates.each do |routine|
        new_routine = routine.clone_to_user(target_user)
        new_routine.program = new_program
        new_routine.save!
      end

      new_program
    end
  end
end
