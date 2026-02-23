module Admin
  class PhasesController < Admin::ApplicationController
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
        respond_to do |format|
          format.html { redirect_to [namespace, requested_resource], notice: translate_with_resource("update.success") }
          format.turbo_stream { render locals: { requested_resource: requested_resource } }
        end
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource),
        }, status: :unprocessable_entity
      end
    end
    def destroy
      authorize_resource(requested_resource)
      if requested_resource.destroy
        respond_to do |format|
          format.html { redirect_to [namespace, requested_resource.class], notice: translate_with_resource("destroy.success") }
          format.turbo_stream { render turbo_stream: turbo_stream.remove(requested_resource) }
        end
      else
        respond_to do |format|
          format.html do
            flash[:error] = requested_resource.errors.full_messages.join("<br/>")
            redirect_to [namespace, requested_resource.class]
          end
          format.turbo_stream { render turbo_stream: turbo_stream.replace(requested_resource, html: "<div class='text-red-500'>Error deleting phase.</div>".html_safe) }
        end
      end
    end
  end
end
