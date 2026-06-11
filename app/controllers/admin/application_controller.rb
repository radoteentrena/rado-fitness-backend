# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Toastable

    before_action :authenticate_admin
    layout "admin/application"

    def authenticate_admin
      authenticate_user!

      unless current_user.admin_role.present?
        flash[:alert] = "You are not authorized to access this page."
        redirect_to root_path
      end
    end

    def require_super_admin
      return redirect_to(root_path) unless current_user
      unless current_user.admin_super_admin?
        flash[:alert] = "This action requires super admin access."
        redirect_to admin_root_path
      end
    end

    def index
      authorize_resource(resource_class)
      search_term = params[:search].to_s.strip
      resources = Administrate::Search.new(scoped_resource, dashboard, search_term).run
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)
      resources = resources.page(params[:page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)

      render locals: {
        resources: resources,
        search_term: search_term,
        page: page,
        show_search_bar: show_search_bar?
      }
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
