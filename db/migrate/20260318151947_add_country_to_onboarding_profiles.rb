class AddCountryToOnboardingProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :onboarding_profiles, :country, :string
  end
end
