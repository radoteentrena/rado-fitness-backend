require "rails_helper"

RSpec.describe DietaryPlan do
  describe ".closest_to_calories" do
    let!(:low)  { DietaryPlan.create!(name: "Cut", calories_target: 1800, protein_target: 150) }
    let!(:mid)  { DietaryPlan.create!(name: "Maintenance", calories_target: 2500, protein_target: 180) }
    let!(:high) { DietaryPlan.create!(name: "Bulk", calories_target: 3200, protein_target: 200) }

    it "returns the plan whose calorie target is nearest" do
      expect(described_class.closest_to_calories(2600)).to eq(mid)
      expect(described_class.closest_to_calories(1850)).to eq(low)
      expect(described_class.closest_to_calories(5000)).to eq(high)
    end

    it "returns nil when target is nil" do
      expect(described_class.closest_to_calories(nil)).to be_nil
    end

    it "ignores plans without a calorie target" do
      DietaryPlan.create!(name: "Draft", calories_target: 2550, protein_target: 100)
                 .update_column(:calories_target, nil)
      expect(described_class.closest_to_calories(2600)).to eq(mid)
    end

    it "returns nil when no plans exist" do
      DietaryPlan.delete_all
      expect(described_class.closest_to_calories(2000)).to be_nil
    end
  end
end
