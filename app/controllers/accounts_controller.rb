# frozen_string_literal: true

class AccountsController < ApplicationController
  layout "homepage"
  before_action :authenticate_user!

  def show
    @subscription = current_user.active_subscription
    if current_user.promoter?
      @promo_links   = current_user.promo_links.includes(:promo_conversions).order(created_at: :desc)
      @pending_cents = current_user.promoter_pending_earnings_cents
      @total_cents   = current_user.promoter_total_earnings_cents
      @tab           = params[:tab] == "campaign" ? "campaign" : "profile"
    end
  end

  def update
    if current_user.update_with_password(password_params)
      bypass_sign_in(current_user)
      redirect_to account_path, notice: "Contraseña actualizada correctamente."
    else
      @subscription = current_user.active_subscription
      render :show, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
