module Admin
  class UserDietaryPlansController < Admin::ApplicationController

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        respond_to do |format|
          format.html { redirect_to [namespace, resource], notice: translate_with_resource("create.success") }
          format.turbo_stream { render locals: { resource: resource } }
        end
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource),
        }, status: :unprocessable_entity
      end
    end

    def update
      if requested_resource.update(resource_params)
        if params[:return_to_user]
          redirect_to admin_user_path(requested_resource.user), status: :see_other, notice: "Plan alimenticio actualizado."
        else
          respond_to do |format|
            format.html { redirect_to [namespace, requested_resource], notice: translate_with_resource("update.success") }
            format.turbo_stream { render locals: { requested_resource: requested_resource } }
          end
        end
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource),
        }, status: :unprocessable_entity
      end
    end

    def destroy
      udp = UserDietaryPlan.find(params[:id])
      user = udp.user
      udp.destroy!
      redirect_to admin_user_path(user), notice: "Plan alimenticio eliminado correctamente."
    end
  end
end
