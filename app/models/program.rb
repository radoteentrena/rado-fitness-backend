class Program < ApplicationRecord
  belongs_to :user, optional: true # Optional if it's a template
  has_many :routines, dependent: :nullify

  after_create_commit :provision_google_sheet, if: -> { user.present? }

  private

  def provision_google_sheet
    ProvisionProgramSheetJob.perform_later(id)
  end

  public

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
