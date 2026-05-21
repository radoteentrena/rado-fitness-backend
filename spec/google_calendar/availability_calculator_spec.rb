require "rails_helper"

RSpec.describe GoogleCalendar::AvailabilityCalculator do
  let(:schedule) { build(:coach_schedule, day_of_week: 1, start_hour: 9, end_hour: 12, active: true) }
  let(:date) { Date.new(2026, 5, 25) } # a Monday

  subject(:calculator) { described_class.new(coach_schedule: schedule, busy_intervals: busy) }

  context "when there are no busy intervals" do
    let(:busy) { [] }

    it "returns all 60-min slots within working hours" do
      slots = calculator.available_slots(date)
      expect(slots.map { |s| s.strftime("%H:%M") }).to eq(%w[09:00 10:00 11:00])
    end
  end

  context "when a slot is fully blocked by a busy interval" do
    let(:busy) do
      [{
        start: date.to_time.change(hour: 10),
        end:   date.to_time.change(hour: 11)
      }]
    end

    it "excludes the blocked slot" do
      slots = calculator.available_slots(date)
      expect(slots.map { |s| s.strftime("%H:%M") }).to eq(%w[09:00 11:00])
    end
  end

  context "when a busy interval overlaps the start of a slot" do
    let(:busy) do
      [{
        start: date.to_time.change(hour: 9, min: 30),
        end:   date.to_time.change(hour: 10, min: 30)
      }]
    end

    it "excludes both overlapping slots" do
      slots = calculator.available_slots(date)
      expect(slots.map { |s| s.strftime("%H:%M") }).to eq(%w[11:00])
    end
  end

  context "when the schedule is inactive" do
    let(:schedule) { build(:coach_schedule, active: false) }
    let(:busy) { [] }

    it "returns no slots" do
      expect(calculator.available_slots(date)).to be_empty
    end
  end
end
