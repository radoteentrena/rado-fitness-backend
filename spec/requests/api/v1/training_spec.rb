require 'rails_helper'

RSpec.describe "Training API", type: :request do
  # Full training chain shared across all training endpoint specs
  let(:user)             { create(:user, status: :active) }
  let(:program)          { create(:program, user: user) }
  let(:phase)            { create(:phase, program: program, order_index: 1, duration_weeks: 4) }
  let(:routine)          { create(:routine, user: user) }
  let!(:phase_routine)   { create(:phase_routine, phase: phase, routine: routine, order_index: 1) }
  let(:workout)          { create(:workout, routine: routine, order_index: 1) }
  let(:exercise)         { create(:exercise) }
  let!(:workout_exercise) { create(:workout_exercise, workout: workout, exercise: exercise) }

  let(:pending_session) do
    create(:training_session,
      user: user, program: program, phase: phase,
      routine: routine, workout: workout,
      status: :pending, cycle_number: 1, session_number: 1)
  end

  let(:in_progress_session) do
    create(:training_session,
      user: user, program: program, phase: phase,
      routine: routine, workout: workout,
      status: :in_progress, started_at: 5.minutes.ago,
      cycle_number: 1, session_number: 1)
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "GET /api/v1/training/current" do
    context "when unauthenticated" do
      it "returns 401" do
        get "/api/v1/training/current"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no pending or in_progress session" do
      it "returns 200 with null session and no_active_program status" do
        get "/api/v1/training/current", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["session"]).to be_nil
        expect(json["status"]).to eq("no_active_program")
      end
    end

    context "with a pending session" do
      before { pending_session }

      it "returns 200 with the session shape" do
        get "/api/v1/training/current", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        sess = json["session"]
        expect(sess).to include("id", "session_number", "status", "phase_name", "cycle_number", "workout")
        expect(sess["status"]).to eq("pending")
        expect(sess["workout"]["exercises"]).to be_an(Array)
      end
    end

    context "with an in_progress session" do
      before { in_progress_session }

      it "returns 200 with status in_progress" do
        get "/api/v1/training/current", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["session"]["status"]).to eq("in_progress")
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "POST /api/v1/training/start" do
    context "when unauthenticated" do
      it "returns 401" do
        post "/api/v1/training/start"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no active session" do
      it "returns 404" do
        post "/api/v1/training/start", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a pending session" do
      before { pending_session }

      it "returns 200 and transitions status to in_progress" do
        post "/api/v1/training/start", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["session"]["status"]).to eq("in_progress")
        expect(pending_session.reload.started_at).not_to be_nil
      end
    end

    context "with an already in_progress session" do
      before { in_progress_session }

      it "returns 200 (idempotent)" do
        post "/api/v1/training/start", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["session"]["status"]).to eq("in_progress")
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "POST /api/v1/training/complete" do
    context "when unauthenticated" do
      it "returns 401" do
        post "/api/v1/training/complete"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no active session" do
      it "returns 404" do
        post "/api/v1/training/complete", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a pending session (not in_progress)" do
      before { pending_session }

      it "returns 422 with an error message" do
        post "/api/v1/training/complete", headers: auth_headers(user)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json["error"]).to be_present
      end
    end

    context "with an in_progress session" do
      before { in_progress_session }

      it "returns 200, completes the session, and creates a ProgramExecution" do
        expect {
          post "/api/v1/training/complete", headers: auth_headers(user)
        }.to change(ProgramExecution, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(json["session"]["status"]).to eq("completed")
      end

      it "includes next_session in the response" do
        post "/api/v1/training/complete", headers: auth_headers(user)
        expect(json).to have_key("next_session")
      end

      context "with exercise_logs" do
        it "creates ExerciseLog records" do
          expect {
            post "/api/v1/training/complete",
              params: {
                exercise_logs: [
                  {
                    workout_exercise_id: workout_exercise.id,
                    actual_sets: [ { reps: 8, weight: 100, rpe: 7 } ]
                  }
                ]
              },
              headers: auth_headers(user)
          }.to change(ExerciseLog, :count).by(1)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "POST /api/v1/training/skip" do
    context "when unauthenticated" do
      it "returns 401" do
        post "/api/v1/training/skip"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no active session" do
      it "returns 404" do
        post "/api/v1/training/skip", headers: auth_headers(user)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with a pending session" do
      before { pending_session }

      it "returns 200 and skips the session" do
        post "/api/v1/training/skip", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["session"]["status"]).to eq("skipped")
      end

      it "includes next_session in the response" do
        post "/api/v1/training/skip", headers: auth_headers(user)
        expect(json).to have_key("next_session")
      end

      it "persists skip_reason when provided" do
        post "/api/v1/training/skip",
          params: { reason: "Feeling sick" },
          headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(pending_session.reload.skip_reason).to eq("Feeling sick")
      end
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  describe "GET /api/v1/training/history" do
    context "when unauthenticated" do
      it "returns 401" do
        get "/api/v1/training/history"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with no completed sessions" do
      it "returns 200 with empty sessions array and zero total_count" do
        get "/api/v1/training/history", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["sessions"]).to eq([])
        expect(json["meta"]["total_count"]).to eq(0)
      end
    end

    context "with completed sessions" do
      let!(:completed_session) do
        create(:training_session,
          user: user, program: program, phase: phase,
          routine: routine, workout: workout,
          status: :completed,
          started_at: 1.hour.ago,
          completed_at: 30.minutes.ago,
          cycle_number: 1, session_number: 1)
      end

      it "returns 200 with the completed session" do
        get "/api/v1/training/history", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json["sessions"].length).to eq(1)
        sess = json["sessions"].first
        expect(sess).to include("session_number", "status", "phase_name", "workout_name", "exercise_logs")
        expect(sess["status"]).to eq("completed")
      end
    end

    context "with pagination" do
      before do
        3.times do |i|
          create(:training_session,
            user: user, program: program, phase: phase,
            routine: routine, workout: workout,
            status: :completed,
            started_at: (i + 2).hours.ago,
            completed_at: (i + 1).hours.ago,
            cycle_number: 1, session_number: i + 1)
        end
      end

      it "respects page and per_page params" do
        get "/api/v1/training/history",
          params: { page: 1, per_page: 2 },
          headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(json["sessions"].length).to eq(2)
        expect(json["meta"]["total_count"]).to eq(3)
        expect(json["meta"]["total_pages"]).to eq(2)
        expect(json["meta"]["current_page"]).to eq(1)
      end
    end
  end
end
