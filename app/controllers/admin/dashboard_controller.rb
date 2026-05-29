module Admin
  class DashboardController < ApplicationController
    def index
      @total_users = User.count
      @active_clients_count = User.where(status: :active).count

      # Optimization Note: For large datasets, caching or a DB column is recommended.
      @low_compliance_users_count = User.where(status: :active).count { |u| u.calculate_diet_consistency_score < 50 }

      @pending_alerts = CoachAlert.pending.includes(:user).order(created_at: :desc).limit(5)

      @recent_users = User.order(created_at: :desc).limit(5)

      @chart_data = User.recent_growth_data

      @calendar_month = begin
        params[:month] ? Date.parse(params[:month]).beginning_of_month : Date.current.beginning_of_month
      rescue ArgumentError
        Date.current.beginning_of_month
      end

      month_bookings = Booking.where(
        scheduled_at: @calendar_month.beginning_of_month..@calendar_month.end_of_month.end_of_day
      ).includes(:user)

      @bookings_by_date = month_bookings.group_by { |b| b.scheduled_at.to_date }

      @upcoming_bookings = Booking.where(scheduled_at: Time.current..)
                                   .where.not(status: :cancelled)
                                   .includes(:user)
                                   .order(:scheduled_at)
                                   .limit(8)
    end
  end
end
