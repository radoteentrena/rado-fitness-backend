module Admin
  class CustomProgramsController < Admin::ApplicationController
    def create
      user = User.find(params[:user_id])
      program = Program.create!(user: user, name: "Programa de #{user.name}")
      redirect_to admin_program_builder_path(program),
                  notice: "Programa creado. Construilo desde acá."
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("CustomProgram error for user #{params[:user_id]}: #{e.message}")
      redirect_to admin_user_path(params[:user_id]),
                  alert: "Error al crear programa: #{e.record.errors.full_messages.to_sentence}"
    end
  end
end
