# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
## [Unreleased]

### Added
- **Deep Training Hierarchy (Epic 4)**:
    - `Program` model for Macrocycles (Template/Instance).
    - `RoutineExercise` (was `RoutineItem`) with daily attributes (`day_number`, `warmup`, `load`).
    - `DietaryPlan` and `UserDietaryPlan` for nutrition tracking.
- **Client Management**:
    - `User` categories (`soldado`, `civil`, `pelele`) and prioritized sorting in Avo.
- **Integrations (Skeleton)**:
    - Mock `Google::SheetsService` for program delivery.
    - Mock `Google::CalendarService` for scheduling.

### Added
- **Deep Training Hierarchy (Epic 4)**:
    - `Program#assign_to_user`: Logic to deep-clone Programs and Routines to clients.
    - Fixed `Routine#clone_to_user` to correctly copy `routine_exercises`.
    - Avo Action: `AssignProgramToUser` for easy assignment from Admin Panel.
- **Dietary Architecture (Epic 4.1)**:
    - `DietaryPlan` as Templates (with targets).
    - `UserDietaryPlan` as Active Instances (with dates and computed stats).
    - `DailyMetric` auto-linking to the active plan.
    - Automated Averages & Progress calculation in Avo.

### Changed
- `Routine` model now represents a specific **Block** (Mesocycle) with `duration_weeks`.
- Renamed `routine_items` table to `routine_exercises`.
- Updated Seeds to provide a full "Hypertrophy Masterclass" example.
### Added
- **AI Integration (Epic 3)**:
    - `DailyMetric` model with `before_save` AI parsing callback.
    - `Avo::Resources::DailyMetric` with JSON highlighting and textarea inputs.
    - `GeminiService`: Interacts with Google Gemini (via `langchainrb`) to parse metrics and generate feedback.
    - `verify_epic_3_integration.rb` for End-to-End verification.
    - `dotenv-rails` for managing environment variables.
- **Data & UI**:
    - Seeded database with 50+ users, real exercises, and 10 routine templates.
    - Themed Avo Admin with "Shadcn" aesthetic (Slate colors, Inter font).
- Core Domain Models: `Exercise`, `Routine`, `RoutineItem` with associations and validations.
- Avo Resources: Configuration for `Exercise`, `Routine`, `RoutineItem`.
- User Invitation Flow: Admins can create users without passwords; system generates temp password and triggers welcome email.
- UI Polish: Avo dropdowns now show names instead of IDs for `User`, `Exercise`, and `Routine`.
- `IDEAS.md` documentation.
- `Routine#clone_to_user` logic for template assignment.
- `verify_epic_2.rb` script for model verification.

### Changed
- Refined `/rado-start` workflow to include Notion sync.

### Added
- User model with Devise authentication, Discard (soft delete), and Enums (status, plan_tier).
- Avo admin panel configuration and User resource.
- Initial project documentation (CONTEXT.md, GEMINI.md).
- Initial project generation with Rails.
