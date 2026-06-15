require "rails_helper"

RSpec.describe ProgramRecordBuilder do
  let(:user) { create(:user) }
  let!(:bench) { create(:exercise, name: "Press de Banca", muscle_group: "Pecho") }

  let(:data) do
    {
      "program" => { "name" => "Plan", "description" => "d", "duration_weeks" => 4 },
      "routines" => [
        {
          "name" => "Hombre Fuerza Intermedio — Full Body",
          "description" => "d", "duration_weeks" => 4,
          "workouts" => [
            {
              "name" => "Día 1", "day_number" => 1,
              "exercises" => [
                { "name" => "Press de Banca", "sets" => 3, "reps" => "8" },
                { "name" => "Ejercicio Inventado", "muscle_group" => "Pecho", "sets" => 3, "reps" => "10" }
              ]
            }
          ]
        }
      ]
    }
  end

  it "only links existing exercises and never creates new ones" do
    builder = described_class.new(data, user)

    expect { builder.build! }.not_to change(Exercise, :count)

    program = Program.last
    workout = program.phases.first.routines.first.workouts.first
    expect(workout.workout_exercises.map { |we| we.exercise }).to eq([bench])
  end

  it "reports the skipped exercises that had no match" do
    builder = described_class.new(data, user)
    builder.build!

    expect(builder.skipped_exercises).to eq(["Ejercicio Inventado"])
  end
end
