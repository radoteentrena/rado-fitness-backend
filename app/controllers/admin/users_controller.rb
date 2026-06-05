module Admin
  class UsersController < Admin::ApplicationController
    def create
      resource = resource_class.new(resource_params)
      authorize_resource(resource)

      if resource.save
        respond_to do |format|
          format.html { redirect_to(
            [ namespace, resource ],
            notice: translate_with_resource("create.success"),
          ) }
          format.turbo_stream {
             collection_page = Administrate::Page::Collection.new(dashboard, order: order)
             render turbo_stream: [
               turbo_stream.replace("users_collection", partial: "admin/users/collection", locals: {
                 collection_presenter: collection_page,
                 collection_field_name: resource_name,
                 page: collection_page,
                 resources: scoped_resource.order(created_at: :desc).page(params[:page]).per(records_per_page)
               }),
               turbo_stream.update("modal_frame", ""),
               turbo_stream.prepend("flash_messages", partial: "admin/application/flash", locals: { message: translate_with_resource("create.success") })
             ]
          }
        end
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, resource)
        }, status: :unprocessable_entity
      end
    end

    def update
      if requested_resource.update(resource_params)
        respond_to do |format|
          format.html { redirect_to(
            [ namespace, requested_resource ],
            notice: translate_with_resource("update.success"),
          ) }
          format.turbo_stream {
             collection_page = Administrate::Page::Collection.new(dashboard, order: order)
             render turbo_stream: [
               turbo_stream.replace("users_collection", partial: "admin/users/collection", locals: {
                 collection_presenter: collection_page,
                 collection_field_name: resource_name,
                 page: collection_page,
                 resources: scoped_resource.order(created_at: :desc).page(params[:page]).per(records_per_page)
               }),
               turbo_stream.update("modal_frame", ""),
               turbo_stream.prepend("flash_messages", partial: "admin/application/flash", locals: { message: translate_with_resource("update.success") })
             ]
          }
        end
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }, status: :unprocessable_entity
      end
    end


    def index
      authorize_resource(resource_class)
      search_term = params[:search].to_s.strip
      resources = Administrate::Search.new(scoped_resource, dashboard, search_term).run
      resources = apply_collection_includes(resources)
      resources = order.apply(resources)

      # Filter by Status (DB)
      if params[:status].present?
        resources = resources.where(status: params[:status])
      end

      # Filter by Plan Tier (DB)
      if params[:plan_tier].present?
        resources = resources.where(plan_tier: params[:plan_tier])
      end

      # Filter by Score (DB)
      if params[:s_score].present?
        resources = resources.with_workout_compliance(params[:s_score])
      end

      if params[:m_score].present?
        resources = resources.with_diet_adherence(params[:m_score])
      end

      resources = resources.page(params[:page]).per(records_per_page)
      page = Administrate::Page::Collection.new(dashboard, order: order)
      render :index, locals: {
        resources: resources,
        search_term: search_term,
        page: page,
        show_search_bar: show_search_bar?
      }
    end

    def show
      authorize_resource(requested_resource)

      @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.current.beginning_of_week
      @view_type = params[:view_type] || "week"

      range = if @view_type == "month"
          @start_date.beginning_of_month..@start_date.end_of_month
      else
          @start_date.beginning_of_week..@start_date.end_of_week
      end


      @daily_metrics = requested_resource.daily_metrics.where(date_logged: range).index_by(&:date_logged)

      @current_weight = requested_resource.latest_weight
      days_back = @view_type == "month" ? 30 : 7
      @weight_trend = requested_resource.weight_trend(days_back)

      render locals: {
        page: Administrate::Page::Show.new(dashboard, requested_resource)
      }
    end

    def promote
      resource = resource_class.find(params[:id])
      resource.update!(promoter: true)
      redirect_to admin_user_path(resource), notice: "#{resource.name} ahora es Promotor."
    end

    def payout_promoter
      resource = resource_class.find(params[:id])
      PromoConversion
        .joins(:promo_link)
        .where(promo_links: { user_id: resource.id }, paid_at: nil)
        .update_all(paid_at: Time.current)
      redirect_to admin_user_path(resource), notice: "Comisiones marcadas como pagadas."
    end

    def create_promo_link
      resource = resource_class.find(params[:id])
      link = resource.promo_links.build(label: params[:label].to_s.strip)
      if link.save
        redirect_to admin_user_path(resource), notice: "Enlace '#{link.label}' creado."
      else
        redirect_to admin_user_path(resource), alert: "Error: #{link.errors.full_messages.join(', ')}"
      end
    end
  end
end
