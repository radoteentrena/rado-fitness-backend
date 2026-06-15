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

  describe "POST /onboarding/check_email" do
    it "reports existence without sending any email" do
      create(:user, email: "known@example.com")

      expect {
        post onboarding_check_email_path, params: { email: "known@example.com" }
      }.not_to have_enqueued_mail(ClientMailer, :payment_link)

      expect(JSON.parse(response.body)["exists"]).to be(true)
    end
  end

  describe "GET /onboarding/email_exists" do
    let!(:user) { create(:user, email: "known@example.com") }

    it "mints a token and emails the payment link when none is valid" do
      expect {
        get onboarding_email_exists_path, params: { email: "known@example.com" }
      }.to have_enqueued_mail(ClientMailer, :payment_link)

      expect(user.reload.payment_token_valid?).to be(true)
    end

    it "does not re-send the email when a valid token already exists" do
      user.generate_payment_token!

      expect {
        get onboarding_email_exists_path, params: { email: "known@example.com" }
      }.not_to have_enqueued_mail(ClientMailer, :payment_link)
    end
  end
end
