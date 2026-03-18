# Epic 5: Client App & API Integration

## Goal
Enable a React Native client app to sync data with the Rails backend, allowing clients to log training, metrics, and communicate with the coach.

## 1. API Architecture
We will expose a RESTful API under `namespace :api`.
*   **Authentication**: Use `devise-jwt` (standard for Rails + React Native) or simple API tokens (easier for MVP).
*   **Versioning**: `Api::V1::...`

### Endpoints
*   `POST /api/v1/login`: Returns JWT/Token.
*   `GET /api/v1/me`: User profile & stats.
*   `POST /api/v1/daily_metrics`: specific fields (weight, steps, etc.).
*   `POST /api/v1/workouts`: Log a completed workout session.
*   `GET /api/v1/program`: Fetch the active program/routine for the user.

## 2. Feature: Training & Metrics Sync
### Current State
*   `DailyMetric` exists (weight, steps, calories).
*   `Program`/`Routine` exists (assigned work).

### Missing / To Build
*   **Detailed Training Logs**: `DailyMetric` only has `workout_completed` (boolean). We need to know *what* they did.
    *   **Option A (Simple)**: Just the boolean + notes.
    *   **Option B (Rich)**: `WorkoutSession` -> `ExerciseLog` (sets, reps, weight). *Strongly recommended for a fitness app.*
    *   **Sync**: When user saves in App -> `POST /api/v1/workouts` -> Creates `WorkoutSession` -> Updates Admin Panel.

## 3. Feature: In-App Messaging (Chat)
Replacement for WhatsApp.

### Data Model
*   **Model**: `Message`
    *   `user_id`: references User.
    *   `sender_type`: enum `{ client: 0, coach: 1, system: 2 }`.
    *   `content`: text.
    *   `read_at`: datetime.
    *   `voice_note`: ActiveStorage attachment (audio/m4a, audio/mp3).

### Capabilities
*   **Text**: Standard CRUD.
*   **Voice**:
    *   **App**: Records audio -> Uploads to `POST /api/v1/messages` as `multipart/form-data`.
    *   **Admin Panel**:
        *   Rado sees a "Chat" interface (Custom Administrate Page or Dashboard).
        *   Audio plays via standard HTML `<audio>` tag in the browser.
        *   Rado can record voice replies (requires JS audio recorder in Admin) or just text.

## 4. Feature: Progress Photos
### Implementation
*   **Storage**: ActiveStorage.
*   **Model**: Add `has_many_attached :progress_photos` to `DailyMetric` OR create `CheckIn` model.
    *   *Recommendation*: Attach to `DailyMetric` to keep it simple. "On this day, here are photos."
*   **Admin Panel**:
    *   **Gallery View**: On User Show page, a defined area showing recent photos.
    *   **Comparison**: Side-by-side view (Before/After).

## 5. Automation & Notifications
*   **Push Notifications**: When Rado replies, User gets a Push (via Firebase FCM).
*   **Admin Alerts**: When User logs a "Weight Spike" or "Missed 3 Workouts", Rado gets an in-app alert (already partially implemented with `CoachAlert`).

## Risks / Considerations
*   **Voice Messages in Admin**: Browsers require microphone permission to record. Playing is easy. Recording from Admin requires a small JS Stimulus controller.
*   **Offline Mode**: React Native app needs to queue requests if offline. Rails API just needs to handle timestamps correctly (don't assume `Time.current`, trust params).
