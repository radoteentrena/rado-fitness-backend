require "rails_helper"

RSpec.describe ExerciseResolver do
  let!(:squat) { create(:exercise, name: "Sentadilla con Barra", muscle_group: "Cuádriceps") }

  it "matches by exact name" do
    resolver = described_class.new
    expect(resolver.resolve("name" => "Sentadilla con Barra")).to eq(squat)
    expect(resolver.skipped).to be_empty
  end

  it "matches case- and accent-insensitively" do
    resolver = described_class.new
    expect(resolver.resolve("name" => "SENTADILLA CON BARRA")).to eq(squat)
    expect(resolver.resolve("name" => "sentadilla con barra")).to eq(squat)
  end

  it "falls back to existing_exercise_id when the name does not match" do
    resolver = described_class.new
    expect(resolver.resolve("name" => "algo distinto", "existing_exercise_id" => squat.id)).to eq(squat)
  end

  it "returns nil and records the name when nothing matches" do
    resolver = described_class.new
    expect(resolver.resolve("name" => "Ejercicio Inventado")).to be_nil
    expect(resolver.skipped).to eq(["Ejercicio Inventado"])
  end

  it "never creates a new exercise" do
    resolver = described_class.new
    expect { resolver.resolve("name" => "No Existe", "muscle_group" => "Pecho") }
      .not_to change(Exercise, :count)
  end
end
