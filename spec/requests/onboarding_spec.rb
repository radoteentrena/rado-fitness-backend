require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  describe "POST /onboarding" do
    context "when form is valid" do
      let(:valid_params) do
        {
          user: {
            first_name: "Test",
            last_name: "User",
            email: "newclient@example.com",
            phone: "+5491155550001",
            onboarding_profile_attributes: {
              gender: "Masculino",
              age: 25,
              weight: "80kg",
              height: "175cm",
              instagram: "testuser",
              experience_level: 5,
              commitment_level: "Alto",
              training_frequency: "4",
              injuries: "Ninguna",
              diet_quality: "Bueno",
              activity_level: "Activo",
              sleep_hours: "6-8",
              social_media_consent: "Si",
              referral_source: "Redes sociales",
              country: "US",
              goals: ["strength"]
            }
          }
        }
      end

      it "redirects to the plan selection page" do
        post onboarding_path, params: valid_params
        expect(response).to redirect_to(new_subscription_path)
      end
    end
  end
end
