require "rails_helper"

RSpec.describe OnboardingProfile, type: :model do
  describe "country validation" do
    it "is valid with a known country code" do
      profile = build(:onboarding_profile, country: "AR")
      expect(profile).to be_valid
    end

    it "is invalid without a country" do
      profile = build(:onboarding_profile, country: nil)
      expect(profile).not_to be_valid
      expect(profile.errors[:country]).to be_present
    end

    it "is invalid with a blank country" do
      profile = build(:onboarding_profile, country: "")
      expect(profile).not_to be_valid
    end
  end

  describe "#argentina?" do
    it "returns true when country is AR" do
      profile = build(:onboarding_profile, country: "AR")
      expect(profile.argentina?).to be true
    end

    it "returns false for other countries" do
      profile = build(:onboarding_profile, country: "US")
      expect(profile.argentina?).to be false
    end
  end
end
