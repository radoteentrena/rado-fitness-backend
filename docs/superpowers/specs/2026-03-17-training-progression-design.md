# Training Progression System — Design Spec
**Date:** 2026-03-17
**Status:** Approved

---

## Overview

A session-based training progression system that allows clients to follow their assigned programs sequentially, day by day, regardless of calendar gaps. Each gym visit advances the client one step through their program. Both client and coach have real-time visibility into position, history, and load progression.

---

## Core Behaviour

- Progression is **session-based, not calendar-based**. Day 2 occurs whenever the client next goes to the gym after Day 1.
- The client explicitly **starts** each session ("Comenzar Sesión") before logging. This prevents accidental advancement.
- Sessions can be **skipped** (with optional reason) from both pending and in-progress states.
- When the last workout of a phase is completed, the system **auto-advances** to the next phase. No coach action required.
- When no next phase exists, the program is marked complete and a coach alert is generated.
- There is always exactly **one** pending or in-progress `TrainingSession` per active user at any time.

---

## Multi-Routine Phases

The schema supports multiple routines per phase via the `phase_routines` join table. **For this iteration, the progression system treats each phase as having one active routine** — the one with the lowest `order_index` in `phase_routines`. If a phase has multiple routines, only the first is used. The join table structure is preserved for future flexibility but the added routines are ignored by the progression engine. Coaches are responsible for enforcing this constraint when building programs.

---

## Validation at Program Assignment

Before creating the first `TrainingSession` for a user, the system must validate:

1. The program has at least one phase.
2. The first phase has at least one routine (via `phase_routines`).
3. That routine has at least one workout.
4. The first phase has `duration_weeks` set to a positive integer (not null, not zero).

If any check fails, session creation is aborted and the assignment raises a descriptive error (surfaced in the admin panel). No partial state is created. The same validation applies when auto-advancing into a new phase.

---

## Data Model

### New: `training_sessions` table

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | PK |
| `user_id` | bigint | FK → users, not null |
| `program_id` | bigint | FK → programs, not null |
| `phase_id` | bigint | FK → phases, not null |
| `routine_id` | bigint | FK → routines, not null |
| `workout_id` | bigint | FK → workouts, not null |
| `cycle_number` | integer | How many times this routine has been cycled (1-based), not null |
| `session_number` | integer | Global sequential session count per user (1-based), not null |
| `status` | integer | Integer-backed enum (see below), not null, default: 0 |
| `started_at` | datetime | Set on transition to `in_progress`; not null when status >= in_progress |
| `completed_at` | datetime | Set on transition to `completed` |
| `skipped_at` | datetime | Set on transition to `skipped` |
| `skip_reason` | string | Optional free-text reason |
| `notes` | text | Optional client notes on session |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Status enum (integer-backed, matching project convention):**
```ruby
enum status: { pending: 0, in_progress: 1, completed: 2, skipped: 3 }
```

**Indexes:**
- `user_id + status` (for fetching current session)
- `user_id + session_number` (for ordered history)
- `workout_id`
- `phase_id` (for phase advancement queries)
- `program_id` (for program-scoped history and completion checks)

**Model validation:** `started_at` must be present when status is `in_progress` or `completed`. It is **not required** for `skipped` sessions transitioning from `pending` (the client never started). Duration in the admin panel shows "—" when `started_at` is null.

### Modified: `program_executions` table

Add column: `training_session_id bigint` (FK → training_sessions, nullable for backwards compatibility with existing records).

Note: `program_executions.workout_id` is kept as-is. It will always match `training_sessions.workout_id` for new records. Both are retained for independent queryability. `workout_id` on `program_executions` may be deprecated in a future migration once all records have a `training_session_id`.

### Existing models unchanged

`ProgramExecution` and `ExerciseLog` remain the detailed exercise log layer. `TrainingSession` is the progression cursor; `ProgramExecution` is the performance record linked to it.

---

## State Machine

```
pending → in_progress   (client taps "Comenzar Sesión")
in_progress → completed (client logs exercises and confirms)
in_progress → skipped   (client taps "Saltar Sesión")
pending → skipped       (client skips before starting)
```

On every terminal transition (`completed` or `skipped`), the system creates the next `pending` TrainingSession before returning. Phase/routine advancement is computed at this point.

---

## Progression Logic

**Within a routine:**
- Workouts are ordered by `order_index` within the routine.
- After completing workout N, the next session points to workout N+1 in the same routine.
- When the last workout of the routine is reached, `cycle_number` increments and the routine restarts from workout 1.
- `routines.duration_weeks` is **not used** by the progression engine. Phase duration is controlled exclusively by `phases.duration_weeks`.

**Phase advancement:**
- `workouts_per_routine` = count of workouts in the phase's primary routine.
- `total_sessions_in_phase` = `phase.duration_weeks × workouts_per_routine`.
- `completed_sessions_in_phase` = count of `TrainingSession` records with `status: completed` for this user + phase.
- When `completed_sessions_in_phase >= total_sessions_in_phase`, advance to next phase.
- Find next phase by `order_index` within the same program.
- If next phase exists: validate it (see above), then create pending session for its primary routine's first workout, cycle 1.
- If no next phase: create `CoachAlert` (category: `program_complete`) and set no further sessions. `program_complete` is a **new category value** that must be added to the `CoachAlert` model's allowed category list alongside the existing values (`missed_workout`, `low_compliance`, `weight_spike`, `check_in`).

**Skipped sessions do not count toward phase completion.** A client who skips often will take longer to advance, accurately reflecting their real training exposure.

---

## API Endpoints

All under `/api/v1/training/`, authenticated via Bearer token.

### `GET /api/v1/training/current`

Returns the current pending or in_progress session.

**No active program / no session:**
```json
HTTP 200
{ "session": null, "status": "no_active_program" }
```

**Active session:**
```json
{
  "session": {
    "id": 42,
    "session_number": 15,
    "status": "pending",
    "phase_name": "Fase 2 — Fuerza",
    "cycle_number": 2,
    "workout": {
      "id": 7,
      "name": "Empuje — Pecho/Hombros/Tríceps",
      "day_number": 3,
      "exercises": [
        {
          "workout_exercise_id": 101,
          "exercise_name": "Press Banca",
          "sets": 4, "reps": 6, "load": "100kg", "early_rpe": 7, "last_rpe": 9,
          "last_logged": {
            "date": "2026-03-10",
            "actual_sets": [{ "reps": 6, "weight": 100, "rpe": 7.5 }, ...]
          }
        }
      ]
    }
  }
}
```

`last_logged` is `null` if the exercise has never been performed.

### `POST /api/v1/training/start`
Transitions `pending → in_progress`. Sets `started_at`. Idempotent if already in_progress.
Returns same shape as `GET /current`.

### `POST /api/v1/training/complete`
Body:
```json
{
  "exercise_logs": [
    { "workout_exercise_id": 101, "actual_sets": [{ "reps": 6, "weight": 102, "rpe": 8 }] }
  ],
  "notes": ""
}
```

- **Partial submissions are accepted.** Exercise logs for a subset of workout exercises are valid — the client may have skipped an exercise. Missing exercises are simply not logged; they will show as no `last_logged` data for that slot.
- Creates `ProgramExecution` linked to this `TrainingSession`. `ProgramExecution.workout_id` is sourced from `TrainingSession.workout_id`.
- Creates `ExerciseLog` records for each submitted exercise.
- Transitions session → `completed`.
- Computes and creates next `pending` TrainingSession (or generates program_complete alert).
- Returns `{ "session": <completed_session>, "next_session": <next_pending_summary> }`.

### `POST /api/v1/training/skip`
Body: `{ "reason": "" }` (optional)
- Transitions session → `skipped`.
- Creates next `pending` TrainingSession.
- Returns `{ "session": <skipped_session>, "next_session": <next_pending_summary> }`.

### `GET /api/v1/training/history`
Query params: `page`, `per_page` (default 20)
Returns paginated list of past sessions (completed + skipped), ordered by `session_number` descending.

```json
{
  "sessions": [
    {
      "id": 41,
      "session_number": 14,
      "status": "completed",
      "phase_name": "Fase 2 — Fuerza",
      "workout_name": "Tirón — Espalda/Bíceps",
      "started_at": "2026-03-14T10:00:00Z",
      "completed_at": "2026-03-14T10:58:00Z",
      "skip_reason": null,
      "exercise_logs": [
        {
          "exercise_name": "Peso Muerto",
          "prescribed": { "sets": 4, "reps": 5, "load": "130kg" },
          "actual_sets": [{ "reps": 5, "weight": 135, "rpe": 8 }]
        }
      ]
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 41
  }
}
```

---

## Admin Panel (View Only)

A new section on the client show page (Administrate) displaying:

**Summary counters:** total sessions, completed, skipped.

**Current position block:**
Phase name · Cycle number · Current workout name · Status badge

**Session history table (collapsed rows, expandable):**
- Completed rows: session number, day label, workout name, date, duration (derived from `completed_at - started_at`)
- Expanded: table of exercises with prescribed vs actual sets/reps/weight/RPE + notes
- Skipped rows: session number, day label, date, reason

Duration display requires `started_at` to be non-null on completed sessions. Model-level validation enforces this (see Data Model section).

This replaces/augments the existing `ProgramExecution` admin view.

---

## Out of Scope (this iteration)

- Coach manually adjusting a client's position (view-only from admin)
- Weight progression recommendations / auto-loading suggestions
- Push notifications for pending sessions
- Rest day enforcement or scheduling
- Multi-routine phase cycling (phases use first routine by `order_index` only)

---

## Key Invariants

1. Exactly one `pending` or `in_progress` session per active user at all times.
2. `session_number` is monotonically increasing per user and never reused.
3. Skipped sessions appear in history but do not advance the phase completion counter.
4. Backwards compatibility: existing `ProgramExecution` records without a `training_session_id` remain valid history.
5. A program with zero phases, or a phase with zero workouts, cannot have sessions created against it — fails at assignment validation with a descriptive error.
