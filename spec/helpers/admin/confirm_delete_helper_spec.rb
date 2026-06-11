require "rails_helper"

RSpec.describe Admin::ConfirmDeleteHelper, type: :helper do
  describe "#confirm_delete_data" do
    it "always sets the confirm-trigger controller" do
      data = helper.confirm_delete_data(create(:exercise))
      expect(data[:controller]).to eq("confirm-trigger")
    end

    context "with an unassigned program (template)" do
      it "uses confirm mode with no warning message" do
        program = create(:program, user: nil)
        data = helper.confirm_delete_data(program)
        expect(data[:confirm_mode]).to be_nil
        expect(data[:confirm_title]).to eq("Eliminar Programa")
        expect(data[:confirm_message]).to be_nil
      end
    end

    context "with a program assigned to a user" do
      it "uses block mode with a blocking message" do
        program = create(:program, user: create(:user))
        data = helper.confirm_delete_data(program)
        expect(data[:confirm_mode]).to eq("block")
        expect(data[:confirm_title]).to eq("No se puede eliminar")
        expect(data[:confirm_message]).to include("desasígnalo primero")
      end
    end

    context "with a routine assigned to a user" do
      it "uses block mode with a feminine-agreement message" do
        routine = create(:routine, user: create(:user))
        data = helper.confirm_delete_data(routine)
        expect(data[:confirm_mode]).to eq("block")
        expect(data[:confirm_message]).to include("desasígnala primero")
      end
    end

    context "with a dietary plan assigned to active users" do
      it "warns with the distinct active-user count" do
        plan = create(:dietary_plan)
        create(:user_dietary_plan, dietary_plan: plan, active: true)
        create(:user_dietary_plan, dietary_plan: plan, active: true)
        create(:user_dietary_plan, dietary_plan: plan, active: false)
        data = helper.confirm_delete_data(plan)
        expect(data[:confirm_title]).to eq("Eliminar Plan Nutricional")
        expect(data[:confirm_message]).to include("2 usuarios activos")
      end

      it "omits the warning when no active users" do
        plan = create(:dietary_plan)
        data = helper.confirm_delete_data(plan)
        expect(data[:confirm_message]).to be_nil
      end
    end

    context "with an exercise used in workouts" do
      it "warns with the workout count" do
        exercise = create(:exercise)
        workout = create(:workout)
        create(:workout_exercise, exercise: exercise, workout: workout)
        data = helper.confirm_delete_data(exercise)
        expect(data[:confirm_title]).to eq("Eliminar Ejercicio")
        expect(data[:confirm_message]).to include("1 entrenamiento")
      end

      it "omits the warning when unused" do
        data = helper.confirm_delete_data(create(:exercise))
        expect(data[:confirm_message]).to be_nil
      end
    end
  end
end
