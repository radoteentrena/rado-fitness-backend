FactoryBot.define do
  factory :onboarding_profile do
    association :user
    gender             { "Masculino" }
    age                { 25 }
    weight             { "80kg" }
    height             { "175cm" }
    instagram          { "testuser" }
    experience_level   { 5 }
    commitment_level   { "Alto" }
    training_frequency { "4" }
    training_years     { "2-5" }
    injuries           { "Ninguna" }
    diet_quality       { "Bueno" }
    activity_level     { "Activo" }
    sleep_hours        { "6-8" }
    social_media_consent { "Si" }
    referral_source    { "Redes sociales" }
    country            { "AR" }
  end
end
