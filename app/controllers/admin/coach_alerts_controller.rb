module Admin
  class CoachAlertsController < Admin::ApplicationController
    def index
      authorize_resource(resource_class)
      search_term = params[:search].to_s.strip
      resources = Administrate::Search.new(scoped_resource, dashboard, search_term).run
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)
      resources = resources.where(status: params[:status]) if params[:status].present?
      resources = resources.where(category: params[:category]) if params[:category].present?
      resources = resources.page(params[:page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)
      render :index, locals: { resources: resources, search_term: search_term, page: page, show_search_bar: show_search_bar? }
    end

    def show
      @coach_alert = CoachAlert.find(params[:id])
    end

    def new
      @coach_alert = CoachAlert.new
    end

    def create
      @coach_alert = CoachAlert.new(coach_alert_params)
      if @coach_alert.save
        redirect_to admin_coach_alerts_path, notice: "Alert created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @coach_alert = CoachAlert.find(params[:id])
    end

    def update
      @coach_alert = CoachAlert.find(params[:id])
      if @coach_alert.update(coach_alert_params)
        redirect_to admin_coach_alert_path(@coach_alert), notice: "Alert updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def resolve
      @coach_alert = CoachAlert.find(params[:id])
      @coach_alert.update!(status: :resolved)
      redirect_to admin_coach_alerts_path, notice: "Alert resolved."
    end

    def dismiss
      @coach_alert = CoachAlert.find(params[:id])
      @coach_alert.update!(status: :dismissed)
      redirect_to admin_coach_alerts_path, notice: "Alert dismissed."
    end

    private

    def coach_alert_params
      params.require(:coach_alert).permit(:user_id, :category, :status, :message, :action_taken)
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
  end
end
