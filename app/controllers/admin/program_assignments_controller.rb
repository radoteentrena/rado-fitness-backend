module Admin
  class ProgramAssignmentsController < Admin::ApplicationController
    def create
      user = User.find(params[:user_id])
      result = ProgramMatcherService.new(user, force: true).call

      if result
        redirect_to admin_user_path(user), notice: "Programa asignado: #{result.name}"
      else
        redirect_to admin_user_path(user), alert: "No se encontraron templates disponibles."
      end
    rescue => e
      Rails.logger.error("ProgramAssignment error for user #{params[:user_id]}: #{e.message}")
      redirect_to admin_user_path(params[:user_id]), alert: "Error al asignar programa: #{e.message}"
    end
  end
end
