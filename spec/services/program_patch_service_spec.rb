require "rails_helper"

RSpec.describe ProgramPatchService do
  let(:program)  { create(:program) }
  let(:phase)    { create(:phase, program: program) }
  let(:routine)  { create(:routine) }
  let(:workout)  { create(:workout, routine: routine) }
  let!(:bench)   { create(:exercise, name: "Press de Banca", muscle_group: "Pecho") }
  let!(:we)      { create(:workout_exercise, workout: workout, exercise: bench, sets: 4, reps: "8-10") }

  before { create(:phase_routine, phase: phase, routine: routine) }

  describe "#call_modifications replace path" do
    it "keeps the existing exercise intact when the suggestion has no match" do
      mods = [
        {
          "workout_exercise_id"         => nil,
          "replace_workout_exercise_id" => we.id,
          "workout_id"                  => workout.id,
          "name"                        => "Ejercicio Inventado",
          "muscle_group"                => "Pecho",
          "sets"                        => 3,
          "reps"                        => "10"
        }
      ]

      service = described_class.new(program, mods)

      expect { service.call_modifications }.not_to change(Exercise, :count)
      expect(WorkoutExercise.exists?(we.id)).to be(true)
      expect(we.reload.exercise).to eq(bench)
      expect(service.skipped_exercises).to eq(["Ejercicio Inventado"])
    end

    it "replaces with an existing exercise when the suggestion matches" do
      replacement = create(:exercise, name: "Sentadilla con Barra", muscle_group: "Cuádriceps")
      mods = [
        {
          "workout_exercise_id"         => nil,
          "replace_workout_exercise_id" => we.id,
          "workout_id"                  => workout.id,
          "name"                        => "Sentadilla con Barra",
          "sets"                        => 5,
          "reps"                        => "5"
        }
      ]

      service = described_class.new(program, mods)

      expect { service.call_modifications }.not_to change(Exercise, :count)
      expect(WorkoutExercise.exists?(we.id)).to be(false)
      expect(workout.reload.workout_exercises.map(&:exercise)).to eq([replacement])
      expect(service.skipped_exercises).to be_empty
    end
  end
end
