module ApplicationHelper
  def admin_user?
    user_signed_in? && current_user.admin_role.present?
  end
end
