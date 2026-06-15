class OnboardingController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  before_action :redirect_if_signed_in, only: [:new, :create]
  layout "homepage"

  def new
    @user = User.new
    @user.build_onboarding_profile

    if params[:promo].present?
      promo_link = PromoLink.active.find_by(code: params[:promo].to_s.upcase)
      session[:promo_code] = promo_link.code if promo_link
    end
  end

  def create
    @user = User.new(onboarding_params)
    @user.status = :lead

    if params[:user][:onboarding_profile_attributes][:goals].is_a?(Array)
      @user.onboarding_profile.goals = params[:user][:onboarding_profile_attributes][:goals].reject(&:blank?)
    end

    if @user.save
      sign_in(@user)
      if ENV["BETA_MODE"] == "true"
        @user.update_columns(status: User.statuses[:active])
        redirect_to onboarding_success_path
      elsif session[:promo_code].present?
        redirect_to new_promo_subscription_path
      else
        redirect_to new_subscription_path
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def check_email
    email = params[:email].to_s.strip.downcase
    render json: { exists: User.exists?(email: email) }
  end

  def email_exists
    @email = params[:email].to_s.strip.downcase
    user = User.find_by(email: @email)
    return unless user

    # Reuse a still-valid token; only mint a new one (and email it) otherwise.
    # Gating the send on fresh-token generation bounds payment-link emails to
    # roughly one per token window per user, preventing email-bombing via
    # repeated requests to this endpoint.
    if user.payment_token_valid?
      token = user.payment_link_token
    else
      token = user.generate_payment_token!
      ClientMailer.payment_link(user).deliver_later
    end

    @payment_url = pay_url(token: token)
  end

  def success
  end

  private

  def redirect_if_signed_in
    redirect_to onboarding_success_path if user_signed_in?
  end

  def onboarding_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :phone,
      onboarding_profile_attributes: [
        :gender, :age, :weight, :height, :instagram,
        :experience_level, :best_lifts, :training_years, :commitment_level,
        :training_frequency, :injuries, :plays_sports, :sport_details,
        :time_per_session, :diet_quality, :activity_level, :sleep_hours,
        :social_media_consent, :referral_source, :referral_source_other,
        :goals_other, :country, goals: []
      ]
    )
  end
end
