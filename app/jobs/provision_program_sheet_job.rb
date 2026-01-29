class ProvisionProgramSheetJob < ApplicationJob
  queue_as :default

  def perform(program_id)
    program = Program.find_by(id: program_id)
    return unless program

    service = Google::SheetsService.new(program)
    service.create_program_sheet
  end
end
