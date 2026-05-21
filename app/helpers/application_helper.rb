module ApplicationHelper
  ADMIN_EMAILS = %w[sam@radoteentrena.com diegue@radoteentrena.com rado@radoteentrena.com].freeze

  def admin_user?
    user_signed_in? && ADMIN_EMAILS.include?(current_user.email)
  end
end
