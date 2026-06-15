require "rails_helper"

RSpec.describe ExerciseVideoHealer do
  # "Press de Banca" has a video; the AI-created "Press de banca" (different
  # casing) does not. They normalize to the same name.
  let!(:canonical) { create(:exercise, name: "Press de Banca", video_link: "https://youtu.be/abc") }
  let!(:duplicate) { create(:exercise, name: "Press de banca", video_link: nil) }

  let(:routine)  { create(:routine) }
  let(:workout)  { create(:workout, routine: routine) }
  let!(:we)      { create(:workout_exercise, workout: workout, exercise: duplicate, sets: 5, reps: "5") }

  context "dry run (default)" do
    it "reports the merge without changing anything" do
      merges = described_class.new.call

      expect(merges.size).to eq(1)
      expect(merges.first.canonical).to eq(canonical)
      expect(merges.first.duplicate).to eq(duplicate)
      expect(merges.first.workout_exercise_count).to eq(1)

      expect(Exercise.exists?(duplicate.id)).to be(true)
      expect(we.reload.exercise).to eq(duplicate)
    end
  end

  context "apply" do
    it "repoints the workout exercise and deletes the duplicate, preserving the row" do
      described_class.new(apply: true).call

      expect(Exercise.exists?(duplicate.id)).to be(false)
      expect(we.reload.exercise).to eq(canonical)
      # the workout_exercise itself (sets/reps) is preserved
      expect(we.sets).to eq(5)
      expect(we.reps).to eq("5")
    end

    it "preserves client training logs (they key on workout_exercise_id)" do
      session = create(:training_session)
      log = ExerciseLog.create!(training_session: session, workout_exercise: we, actual_sets: [{ "reps" => 5 }])

      described_class.new(apply: true).call

      expect(ExerciseLog.exists?(log.id)).to be(true)
      expect(log.reload.workout_exercise).to eq(we)
    end
  end

  it "ignores a videoless exercise that has no video-bearing twin" do
    lonely = create(:exercise, name: "Hip Thrust", video_link: nil)
    merges = described_class.new.call
    expect(merges.map(&:duplicate)).not_to include(lonely)
  end
end
