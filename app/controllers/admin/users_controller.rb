module Admin
  class UsersController < Admin::ApplicationController
    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        respond_to do |format|
          format.html { redirect_to(
            [namespace, resource],
            notice: translate_with_resource("create.success"),
          ) }
          format.turbo_stream {
             render turbo_stream: [
               turbo_stream.replace("users_collection", partial: "collection", locals: { resources: scoped_resource.order(created_at: :desc).page(params[:page]).per(10) }),
               turbo_stream.update("modal_frame", ""),
               turbo_stream.prepend("flash_messages", partial: "admin/application/flash", locals: { message: translate_with_resource("create.success") })
             ]
          }
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
          format.html { redirect_to(
            [namespace, requested_resource],
            notice: translate_with_resource("update.success"),
          ) }
          format.turbo_stream {
            render turbo_stream: [
               turbo_stream.replace("users_collection", partial: "collection", locals: { resources: scoped_resource.order(created_at: :desc).page(params[:page]).per(10) }),
               turbo_stream.update("modal_frame", ""),
               turbo_stream.prepend("flash_messages", partial: "admin/application/flash", locals: { message: translate_with_resource("update.success") })
            ]
          }
        end
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource),
        }, status: :unprocessable_entity
      end
    end

    private

    # Re-implementing scoped_resource to ensure we can use it in the stream
    # Although it is inherited, good to be explicit if we are changing things.
    # We will trust the inherited one for now, but we need to make sure we load the correct resources for the list.
    # In the index action, Administrate does:
    # resources = scoped_resource.includes(*resource_includes)
    # resources = filter_resources(resources, search_term: params[:search])
    # resources = order.apply(resources)
    # resources = resources.page(params[:page]).per(records_per_page)
    #
    # Replicating that exact logic here for the stream might be repetitive.
    # Simpler approach: Just reload the 1st page or the current page?
    # For now, I'll just reload the basic sorted list to prove it works.
    # NOTE: Does this controller have access to filter_resources? Yes, it inherits from Admin::ApplicationController.

    # Ideally we should DRY this up, but for now getting the stream working is priority.
  end
end
