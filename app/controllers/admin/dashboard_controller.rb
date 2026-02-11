module Admin
  class DashboardController < ApplicationController
    def index
      @total_users = User.count
      @active_clients_count = User.where(status: :active).count

      # Calculate low compliance users (consistency_score < 50)
      # Optimization Note: For large datasets, caching or a DB column is recommended.
      @low_compliance_users_count = User.where(status: :active).count { |u| u.respond_to?(:consistency_score) && u.consistency_score < 50 }

      @pending_alerts = CoachAlert.pending.includes(:user).order(created_at: :desc).limit(5)

      @recent_users = User.order(created_at: :desc).limit(5)

      # Chart Data: Last 7 Days User Growth
      # Group by date for the chart
      data = User.where("created_at > ?", 7.days.ago).group("DATE(created_at)").count
      # Fill missing dates with 0
      (7.days.ago.to_date..Date.today).each { |date| data[date] ||= 0 }

      # Sort by date
      sorted_data = data.sort.to_h

      @chart_data = {
        categories: sorted_data.keys.map { |d| d.strftime("%d %b") },
        series: [{ name: "New Users", data: sorted_data.values }]
      }
    end
  end
end
