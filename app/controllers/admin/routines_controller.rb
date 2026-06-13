module Admin
  class RoutinesController < Admin::ApplicationController
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

    def show
      @routine = requested_resource
      @selected_workout = @routine.workouts.find_by(id: params[:workout_id]) || @routine.workouts.order(:day_number, :order_index).first
      @phase = @routine.phases.find_by(id: params[:phase_id]) || @routine.phases.first
      if @phase
        @program = @phase.program
        @routines = @phase.routines.order('phase_routines.order_index')
      end
      render layout: "routine_viewer"
    end

    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        respond_to do |format|
          format.html { redirect_to [namespace, resource], notice: translate_with_resource("create.success") }
          format.turbo_stream { render locals: { resource: resource, phase_id: params[:phase_id] } }
        end
      else
        respond_to do |format|
          format.html { render :new, locals: { page: Administrate::Page::Form.new(dashboard, resource) }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if requested_resource.update(resource_params)
        respond_to do |format|
          format.html { redirect_back_or_to [namespace, requested_resource], notice: translate_with_resource("update.success") }
          format.turbo_stream { render locals: { requested_resource: requested_resource } }
        end
      else
        respond_to do |format|
          format.html { render :edit, locals: { page: Administrate::Page::Form.new(dashboard, requested_resource) }, status: :unprocessable_entity }
        end
      end
    end

    def apply_collection_includes(collection)
      collection
    end

    def scoped_resource
      scope = super.where(is_template: true)
      scope = scope.where("name ILIKE ?", "%#{params[:gender]}%")  if params[:gender].present?
      scope = scope.where("name ILIKE ?", "%#{params[:focus]}%")   if params[:focus].present?
      scope = scope.where("name ILIKE ?", "%#{params[:level]}%")   if params[:level].present?
      scope
    end

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
  end
end
