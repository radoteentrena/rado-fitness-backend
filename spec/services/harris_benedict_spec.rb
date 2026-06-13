require "rails_helper"

RSpec.describe HarrisBenedict do
  def build_user(gender: "Masculino", age: 25, weight: "80kg", height: "175cm", activity_level: "Activo")
    user = create(:user)
    profile = build(:onboarding_profile, user: user, gender: gender, age: age, weight: weight, height: height,
                    activity_level: activity_level)
    profile.save!(validate: false)
    user
  end

  describe ".bmr" do
    it "computes male BMR with the revised Harris-Benedict equation" do
      user = build_user
      # 88.362 + 13.397*80 + 4.799*175 - 5.677*25 = 1858.2 -> 1858
      expect(described_class.bmr(user)).to eq(1858)
    end

    it "computes female BMR" do
      user = build_user(gender: "Femenino", age: 30, weight: "60", height: "165")
      # 447.593 + 9.247*60 + 3.098*165 - 4.330*30 = 1383.7 -> 1384
      expect(described_class.bmr(user)).to eq(1384)
    end

    it "parses height in meters" do
      user = build_user(height: "1.75m")
      expect(described_class.bmr(user)).to eq(1858)
    end

    it "parses comma decimals" do
      user = build_user(height: "1,75")
      expect(described_class.bmr(user)).to eq(1858)
    end

    it "falls back to the latest logged daily metric weight when profile weight is unparseable" do
      user = build_user(weight: "n/a")
      create(:daily_metric, user: user, weight: 80, date_logged: Date.current)
      expect(described_class.bmr(user)).to eq(1858)
    end

    it "returns nil when the user has no onboarding profile" do
      expect(described_class.bmr(create(:user))).to be_nil
    end

    it "returns nil when gender is unrecognized" do
      expect(described_class.bmr(build_user(gender: "Otro"))).to be_nil
    end

    it "returns nil when height is unparseable" do
      expect(described_class.bmr(build_user(height: "tall"))).to be_nil
    end

    it "returns nil when age is missing" do
      expect(described_class.bmr(build_user(age: nil))).to be_nil
    end
  end

  describe ".tdee" do
    # Base male BMR for 80kg / 175cm / 25y = 1858
    it "multiplies BMR by the 'Activo' activity factor (1.55)" do
      user = build_user(activity_level: "Activo")
      expect(described_class.tdee(user)).to eq((1858 * 1.55).round) # 2880
    end

    it "multiplies BMR by the 'Sentado' activity factor (1.2)" do
      user = build_user(activity_level: "Sentado")
      expect(described_class.tdee(user)).to eq((1858 * 1.2).round) # 2230
    end

    it "uses the default factor (1.375) for an unrecognized activity_level" do
      user = build_user(activity_level: "Astronauta")
      expect(described_class.tdee(user)).to eq((1858 * 1.375).round) # 2555
    end

    it "returns nil when BMR cannot be computed" do
      expect(described_class.tdee(create(:user))).to be_nil
    end
  end
end
