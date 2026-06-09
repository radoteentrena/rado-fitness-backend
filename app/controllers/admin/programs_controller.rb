module Admin
  class ProgramsController < Admin::ApplicationController
    def apply_collection_includes(collection)
      collection.includes(:user)
    end

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        redirect_to [namespace, resource], notice: translate_with_resource("create.success")
      else
        respond_to do |format|
          format.html { render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if requested_resource.update(resource_params)
        redirect_to [namespace, requested_resource], notice: translate_with_resource("update.success")
      else
        respond_to do |format|
          format.html { render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) }, status: :unprocessable_entity }
        end
      end
    end

    # Overwrite any of the RESTful controller actions to implement custom behavior
    # For example, you may want to send an email after a foo is updated.
    #
    # def update
    #   super
    #   send_foo_updated_email(requested_resource)
    # end

    # Override this method to specify custom lookup behavior.
    # This will be used to set the resource for the `show`, `edit`, and `update`
    # actions.
    #
    # def find_resource(param)
    #   Foo.find_by!(slug: param)
    # end

    # The result of this lookup will be available as `requested_resource`

    # Override this if you have certain roles that require a subset
    # this will be used to set the records shown on the `index` action.
    #
    # def scoped_resource
    #   if current_user.super_admin?
    #     resource_class
    #   else
    #     resource_class.with_less_stuff
    #   end
    # end

    # Override `resource_params` if you want to transform the submitted
    # data before it's persisted. For example, the following would turn all
    # empty values into nil values. It uses other APIs such as `resource_class`
    # and `dashboard`:
    #
    # def resource_params
    #   params.require(resource_class.model_name.param_key).
    #     permit(dashboard.permitted_attributes(action_name)).
    #     transform_values { |value| value == "" ? nil : value }
    # end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
    def remove_user
      program = Program.find(params[:id])
      program.update!(user_id: nil)
      redirect_to admin_program_path(program), notice: "Usuario removido del programa."
    end

    def sync_sheet
      program = Program.find(params[:id])
      service = Google::SheetsService.new(program)

      if service.sync_to_db
        redirect_to admin_program_path(program), notice: "Program synced successfully from Google Sheets."
      else
        redirect_to admin_program_path(program), alert: "Failed to sync from Google Sheets. Ensure credentials are set."
      end
    end

    def destroy
      program = Program.find(params[:id])
      user = program.user
      name = program.name
      
      if program.destroy
        redirect_to(user ? admin_user_path(user) : admin_programs_path, notice: "Programa \"#{name}\" eliminado correctamente.")
      else
        redirect_to(admin_program_path(program), alert: program.errors.full_messages.to_sentence)
      end
    end

    def remove_user
      program = Program.find(params[:id])
      user = program.user
      
      if user && program.update(user: nil)
        redirect_to admin_user_path(user), notice: "Programa desasignado correctamente. Ahora es un template."
      else
        redirect_to admin_programs_path, alert: "No se pudo desasignar el programa."
      end
    end
  end
end
