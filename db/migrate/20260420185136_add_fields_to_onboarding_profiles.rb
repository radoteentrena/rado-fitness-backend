class AddFieldsToOnboardingProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :onboarding_profiles, :training_years, :string
    add_column :onboarding_profiles, :goals_other, :string
    add_column :onboarding_profiles, :referral_source_other, :string
  end
end
