module Admin
  class ProgramAssignmentsController < Admin::ApplicationController
    def new
      @user = User.find(params[:user_id])
      @templates = Program.where(user_id: nil).includes(:phases).order(:name)
      render layout: false
    end

    def create
      user = User.find(params[:user_id])

      if params[:program_id].present?
        program = Program.find(params[:program_id])
        if program.user.present?
          redirect_to admin_user_path(user), alert: "El programa ya está asignado a otro usuario." and return
        end
        program.update!(user: user)
        TrainingProgressionService.create_initial_session(user, program)
        redirect_to admin_user_path(user), notice: "Programa \"#{program.name}\" asignado."
      else
        result = ProgramMatcherService.new(user, force: true).call
        if result
          redirect_to admin_user_path(user), notice: "Programa asignado: #{result.name}"
        else
          redirect_to admin_user_path(user), alert: "No se encontraron templates disponibles."
        end
      end
    rescue => e
      Rails.logger.error("ProgramAssignment error for user #{params[:user_id]}: #{e.message}")
      redirect_to admin_user_path(params[:user_id]), alert: "Error al asignar programa: #{e.message}"
    end
  end
end
