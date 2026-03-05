class OnboardingController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  layout "homepage"

  def new
    @user = User.new
    @user.build_onboarding_profile
  end

  def create
    @user = User.new(onboarding_params)
    @user.status = :lead

    if params[:user][:onboarding_profile_attributes][:goals].is_a?(Array)
      @user.onboarding_profile.goals = params[:user][:onboarding_profile_attributes][:goals].reject(&:blank?)
    end

    if @user.save
      redirect_to onboarding_success_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def onboarding_params
    params.require(:user).permit(
      :first_name, :last_name, :email, :phone,
      onboarding_profile_attributes: [
        :gender, :age, :weight, :height, :instagram,
        :experience_level, :best_lifts, :commitment_level,
        :training_frequency, :injuries, :plays_sports, :sport_details,
        :time_per_session, :diet_quality, :activity_level, :sleep_hours,
        :social_media_consent, :referral_source, goals: []
      ]
    )
  end
end
