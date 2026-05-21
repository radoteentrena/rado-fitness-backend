module Admin
  class SubscriptionsController < Admin::ApplicationController
    def index
      scope = Subscription.includes(:user).order(created_at: :desc)
      scope = scope.where(status: params[:status])       if params[:status].present?
      scope = scope.where(plan_tier: params[:plan_tier]) if params[:plan_tier].present?

      @resources = scope.page(params[:_page])
      page = Administrate::Page::Collection.new(dashboard)

      render locals: {
        resources: @resources,
        page: page,
        search_term: nil,
        show_search_bar: false
      }
    end
  end
end
