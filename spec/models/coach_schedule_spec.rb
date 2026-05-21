require "rails_helper"

RSpec.describe CoachSchedule, type: :model do
  describe "validations" do
    subject { build(:coach_schedule, day_of_week: 3) }

    it { is_expected.to validate_presence_of(:day_of_week) }
    it { is_expected.to validate_presence_of(:start_hour) }
    it { is_expected.to validate_presence_of(:end_hour) }
    it { is_expected.to validate_uniqueness_of(:day_of_week) }

    it "is invalid when end_hour <= start_hour" do
      schedule = build(:coach_schedule, start_hour: 10, end_hour: 9)
      expect(schedule).not_to be_valid
      expect(schedule.errors[:end_hour]).to include("must be after start_hour")
    end

    it "is valid with start_hour < end_hour" do
      expect(build(:coach_schedule, day_of_week: 3, start_hour: 9, end_hour: 18)).to be_valid
    end
  end

  describe "#day_name" do
    it "returns the correct day name" do
      expect(build(:coach_schedule, day_of_week: 1).day_name).to eq("Monday")
      expect(build(:coach_schedule, day_of_week: 0).day_name).to eq("Sunday")
    end
  end
end
