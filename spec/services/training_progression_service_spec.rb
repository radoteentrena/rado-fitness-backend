require "rails_helper"

RSpec.describe TrainingProgressionService do
  # ─── Shared program structure ───────────────────────────────────────────────
  let(:user)    { create(:user, status: :active) }
  let(:program) { create(:program, user: user) }
  let(:phase)   { create(:phase, program: program, order_index: 1, duration_weeks: 4) }
  let(:routine) { create(:routine) }
  let!(:phase_routine) { create(:phase_routine, phase: phase, routine: routine, order_index: 1) }
  let!(:workout_a) { create(:workout, routine: routine, name: "Day A", order_index: 1) }
  let!(:workout_b) { create(:workout, routine: routine, name: "Day B", order_index: 2) }

  # ─── create_initial_session ─────────────────────────────────────────────────
  describe ".create_initial_session" do
    it "creates a pending session on the first workout of the primary routine" do
      session = described_class.create_initial_session(user, program)

      expect(session).to be_persisted
      expect(session.status).to eq("pending")
      expect(session.workout).to eq(workout_a)
      expect(session.routine).to eq(routine)
      expect(session.phase).to eq(phase)
    end

    it "closes any existing pending sessions before creating the new one" do
      stale = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :pending, cycle_number: 1, session_number: 1)

      described_class.create_initial_session(user, program)

      expect(stale.reload.status).to eq("skipped")
      expect(stale.reload.skip_reason).to match(/Superseded/)
    end

    it "closes any existing in_progress sessions before creating the new one" do
      stale = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :in_progress, started_at: 1.hour.ago,
        cycle_number: 1, session_number: 1)

      described_class.create_initial_session(user, program)

      expect(stale.reload.status).to eq("skipped")
    end

    it "uses next_session_number rather than hardcoding 1" do
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :completed, started_at: 2.hours.ago, completed_at: 1.hour.ago,
        cycle_number: 1, session_number: 5)

      session = described_class.create_initial_session(user, program)

      expect(session.session_number).to eq(6)
    end

    it "rolls back if session creation fails, leaving stale session intact" do
      stale = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :pending, cycle_number: 1, session_number: 1)

      allow(TrainingSession).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect { described_class.create_initial_session(user, program) }.to raise_error(ActiveRecord::RecordInvalid)
      expect(stale.reload.status).to eq("pending")
    end

    it "raises if the phase has no duration_weeks" do
      phase.update!(duration_weeks: nil)

      expect { described_class.create_initial_session(user, program) }
        .to raise_error(ArgumentError, /duration_weeks/)
    end

    it "raises if the phase has no routines" do
      phase_routine.destroy

      expect { described_class.create_initial_session(user, program) }
        .to raise_error(ArgumentError, /rutinas asignadas/)
    end
  end

  # ─── start_session ──────────────────────────────────────────────────────────
  describe ".start_session" do
    context "with a pending session" do
      let(:session) do
        create(:training_session,
          user: user, program: program, phase: phase,
          routine: routine, workout: workout_a,
          status: :pending, cycle_number: 1, session_number: 1)
      end

      it "transitions to in_progress" do
        described_class.start_session(session)
        expect(session.reload.status).to eq("in_progress")
        expect(session.reload.started_at).not_to be_nil
      end
    end

    context "with an already in_progress session" do
      let(:session) do
        create(:training_session,
          user: user, program: program, phase: phase,
          routine: routine, workout: workout_a,
          status: :in_progress, started_at: 5.minutes.ago,
          cycle_number: 1, session_number: 1)
      end

      it "returns the session without error (idempotent)" do
        result = described_class.start_session(session)
        expect(result).to eq(session)
        expect(session.reload.status).to eq("in_progress")
      end

      context "when the routine has been reassigned since the session started" do
        let(:new_routine)  { create(:routine) }
        let!(:new_workout) { create(:workout, routine: new_routine, name: "New Day A", order_index: 1) }

        before do
          phase_routine.update!(routine: new_routine)
        end

        it "reconciles the stale routine even on an in_progress session" do
          described_class.start_session(session)

          expect(session.reload.routine).to eq(new_routine)
          expect(session.reload.workout).to eq(new_workout)
        end
      end
    end

    context "with a completed session" do
      let(:session) do
        create(:training_session,
          user: user, program: program, phase: phase,
          routine: routine, workout: workout_a,
          status: :completed, started_at: 2.hours.ago, completed_at: 1.hour.ago,
          cycle_number: 1, session_number: 1)
      end

      it "raises ArgumentError" do
        expect { described_class.start_session(session) }
          .to raise_error(ArgumentError, /pendiente/)
      end
    end
  end

  # ─── reconcile_stale_routine! ───────────────────────────────────────────────
  describe ".reconcile_stale_routine!" do
    let(:session) do
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :pending, cycle_number: 1, session_number: 1)
    end

    it "does nothing when routine is still current" do
      expect { described_class.reconcile_stale_routine!(session) }
        .not_to change { session.reload.routine_id }
    end

    it "updates routine and resets to first workout when routine has changed" do
      new_routine  = create(:routine)
      new_workout  = create(:workout, routine: new_routine, name: "New A", order_index: 1)
      phase_routine.update!(routine: new_routine)

      described_class.reconcile_stale_routine!(session)

      expect(session.reload.routine).to eq(new_routine)
      expect(session.reload.workout).to eq(new_workout)
    end
  end

  # ─── advance_progression ────────────────────────────────────────────────────
  describe "progression after completing a session" do
    let(:session) do
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :in_progress, started_at: 30.minutes.ago,
        cycle_number: 1, session_number: 1)
    end

    it "creates a pending session for the next workout in the routine" do
      result = described_class.complete_session(session)

      next_session = result[:next_session]
      expect(next_session).to be_persisted
      expect(next_session.status).to eq("pending")
      expect(next_session.workout).to eq(workout_b)
      expect(next_session.cycle_number).to eq(1)
    end

    it "cycles back to the first workout with an incremented cycle after all workouts are done" do
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :completed, started_at: 1.hour.ago, completed_at: 50.minutes.ago,
        cycle_number: 1, session_number: 1)

      last_session = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_b,
        status: :in_progress, started_at: 30.minutes.ago,
        cycle_number: 1, session_number: 2)

      result = described_class.complete_session(last_session)

      next_session = result[:next_session]
      expect(next_session.workout).to eq(workout_a)
      expect(next_session.cycle_number).to eq(2)
    end

    it "picks up a workout added to the routine mid-cycle instead of skipping it" do
      # workout_a completed — at that moment workout_c did not exist in the routine
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :completed, started_at: 1.hour.ago, completed_at: 50.minutes.ago,
        cycle_number: 1, session_number: 1)

      # Coach inserts workout_c between workout_a and workout_b
      workout_c = create(:workout, routine: routine, name: "Day C", order_index: 2)
      workout_b.update!(order_index: 3)

      # Now completing workout_b should find workout_c (unattempted, order_index 2) next
      last_session = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_b,
        status: :in_progress, started_at: 30.minutes.ago,
        cycle_number: 1, session_number: 2)

      result = described_class.complete_session(last_session)

      next_session = result[:next_session]
      expect(next_session.workout).to eq(workout_c)
      expect(next_session.cycle_number).to eq(1)
    end

    it "does not create a duplicate session when a pending session already exists for a workout" do
      # Both workouts have sessions in cycle 1 — workout_b is pending, not yet done
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :completed, started_at: 1.hour.ago, completed_at: 50.minutes.ago,
        cycle_number: 1, session_number: 1)
      create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_b,
        status: :pending,
        cycle_number: 1, session_number: 2)

      # Completing workout_a again (e.g. a retry scenario) should not duplicate workout_b
      retry_session = create(:training_session,
        user: user, program: program, phase: phase,
        routine: routine, workout: workout_a,
        status: :in_progress, started_at: 30.minutes.ago,
        cycle_number: 1, session_number: 3)

      expect {
        described_class.complete_session(retry_session)
      }.not_to change { TrainingSession.where(workout: workout_b, cycle_number: 1).count }
    end
  end
end
