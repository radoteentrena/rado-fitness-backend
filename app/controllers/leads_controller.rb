class LeadsController < ApplicationController
  # Publicly accessible onboarding form
  skip_before_action :authenticate_user!, raise: false
  layout "homepage" # Use the dark theme layout

  def new
    @lead = Lead.new
  end

  def create
    @lead = Lead.new(lead_params)

    @lead.goals = params[:lead][:goals].reject(&:blank?) if params[:lead][:goals].is_a?(Array)

    if @lead.save
      redirect_to success_leads_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
  end

  private

  def lead_params
    params.require(:lead).permit(
      :name, :last_name, :gender, :age, :weight, :height, :email, :phone,
      :instagram, :experience_level, :best_lifts, :commitment_level,
      :training_frequency, :injuries, :plays_sports, :sport_details,
      :time_per_session, :diet_quality, :activity_level, :sleep_hours,
      :social_media_consent, :referral_source, goals: []
    )
  end
end
