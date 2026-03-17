class CreateOnboardingProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :onboarding_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :gender
      t.integer :age
      t.string :weight
      t.string :height
      t.string :instagram
      t.jsonb :goals
      t.integer :experience_level
      t.text :best_lifts
      t.string :commitment_level
      t.string :training_frequency
      t.text :injuries
      t.string :plays_sports
      t.string :sport_details
      t.string :time_per_session
      t.string :diet_quality
      t.string :activity_level
      t.string :sleep_hours
      t.string :social_media_consent
      t.string :referral_source

      t.timestamps
    end
  end
end
