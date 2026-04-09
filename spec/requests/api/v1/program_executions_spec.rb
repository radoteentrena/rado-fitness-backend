require 'rails_helper'

RSpec.describe "POST /api/v1/program_executions", type: :request do
  let(:user)    { create(:user, status: :active) }
  let(:routine) { create(:routine) }
  let(:workout) { create(:workout, routine: routine) }

  context "when unauthenticated" do
    it "returns 401" do
      post "/api/v1/program_executions"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    context "with valid params (workout_id + completed_at)" do
      it "returns 201 with id and success message" do
        expect {
          post "/api/v1/program_executions",
            params: {
              program_execution: {
                workout_id: workout.id,
                completed_at: Time.current.iso8601
              }
            },
            headers: auth_headers(user)
        }.to change(user.program_executions, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json).to include("id", "message")
      end
    end

    context "with exercise_logs_attributes" do
      let(:exercise)         { create(:exercise) }
      let(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }

      it "returns 201 and creates associated ExerciseLogs" do
        expect {
          post "/api/v1/program_executions",
            params: {
              program_execution: {
                workout_id: workout.id,
                completed_at: Time.current.iso8601,
                exercise_logs_attributes: [
                  {
                    workout_exercise_id: workout_exercise.id,
                    actual_sets: [ { reps: 8, load: 100, rir: 1 } ]
                  }
                ]
              }
            },
            headers: auth_headers(user)
        }.to change(ExerciseLog, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context "without workout_id" do
      it "returns 422" do
        post "/api/v1/program_executions",
          params: { program_execution: { completed_at: Time.current.iso8601 } },
          headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
