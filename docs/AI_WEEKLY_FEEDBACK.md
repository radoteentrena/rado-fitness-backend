# AI Weekly Feedback - Implementation Plan

## Goal Description
Automate the generation of weekly client feedback using Gemini AI. The system will aggregate a user's weekly `DailyMetric` logs (nutrition/weight) and `Workout` adherence to produce a concise, coach-style summary (Persona: "Rado" - direct, tough love, motivating). This feedback will be stored in a new `WeeklyCheckin` model and can be reviewed/edited by the admin before sending.

## User Review Required
> [!IMPORTANT]
> **Prompt Engineering**: We need to fine-tune the "Rado" persona. I will propose a baseline prompt, but you should review tone.

> [!NOTE]
> **Data Model**: I am proposing a new `WeeklyCheckin` model to store these feedbacks permanently.

## Proposed Changes

### Database & Models
#### [NEW] [WeeklyCheckin](file:///app/models/weekly_checkin.rb)
*   **Belongs to:** `User`
*   **Fields:**
    *   `week_start` (Date)
    *   `week_end` (Date)
    *   `metrics_summary` (JSON) - Snapshot of the data used for generation.
    *   `ai_feedback` (Text) - The generated raw feedback.
    *   `admin_notes` (Text) - Manual overrides/adjustments.
    *   `status` (Enum: `pending`, `reviewed`, `sent`)

### Services
#### [MODIFY] [GeminiService](file:///app/services/gemini_service.rb)
*   Add method `generate_weekly_feedback(user, start_date, end_date)`
*   Logic:
    1.  Fetch `DailyMetrics` for the date range.
    2.  Calculate averages (Weight, Calories, Protein).
    3.  Calculate Compliance Scores (S%, M%).
    4.  Construct Prompt with:
        *   User Name & Goal (from User profile/Category).
        *   The aggregated data.
        *   "Rado" Persona instructions.
    5.  Call Gemini API.
    6.  Return text.

### Admin UI (Administrate)
#### [NEW] [WeeklyCheckinDashboard](file:///app/dashboards/weekly_checkin_dashboard.rb)
*   Display inputs and generated outputs.
*   Action: "Generate AI Feedback" (triggers service).

## Verification Plan

### Automated Tests
*   `spec/services/gemini_service_spec.rb`: Mock Gemini API response and verify prompt construction.
*   `spec/models/weekly_checkin_spec.rb`: Verify associations and enums.

### Manual Verification
*   Create a `WeeklyCheckin` for a test user (e.g., "Soldado Test").
*   Click "Generate".
*   Verify the tone and data accuracy of the output.
