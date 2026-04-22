module Admin
  class DashboardController < ApplicationController
    def index
      @total_users = User.count
      @active_clients_count = User.where(status: :active).count

      # Calculate low compliance users (diet_consistency_score < 50)
      # Optimization Note: For large datasets, caching or a DB column is recommended.
      @low_compliance_users_count = User.where(status: :active).count { |u| u.calculate_diet_consistency_score < 50 }

      @pending_alerts = CoachAlert.pending.includes(:user).order(created_at: :desc).limit(5)

      @recent_users = User.order(created_at: :desc).limit(5)

      @chart_data = User.recent_growth_data
    end
  end
end
