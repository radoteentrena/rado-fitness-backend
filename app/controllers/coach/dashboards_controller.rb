class Coach::DashboardsController < ApplicationController
  # layout "coach" # Optional: if we want a separate layout later

  def show
    @pending_alerts = CoachAlert.pending.includes(:user).order(created_at: :desc)
    @active_clients_count = User.where(status: :active).count # Assuming 'active' status or similar exists?
    # Use User.kept.count or User.count if status not defined yet.
    # Let's check User model for scopes.

    # Simple metrics for now
    @total_users = User.count
    # consistency_score is a method, not a column, so we must load users or default to 0
    # For performance with many users, we should eventually cache this column.
    @low_compliance_users = User.all.select { |u| u.consistency_score < 50 }.count
  end
end
