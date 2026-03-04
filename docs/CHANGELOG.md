# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- **UI:** New Homepage implementation with `PagesController#home`, featuring improved copy and structure.
- **UI:** Dedicated `homepage` layout for full-width sections.

### Changed
- **Routing:** Updated root path to `pages#home`.
- **Refactor:** Removed legacy `HomeController` and `home/index.html.erb` in favor of new structure.

### Fixed
- **UI:** Resolved font-display fallback by importing the `Inter` font in application layouts.
- **Admin UI:** Fixed horizontal overflow on "Load" text fields by applying appropriate min-width and block display constraints.
- **Admin UI:** Updated routine sidebar back button behavior to track browser history.
- **Admin UI:** Corrected badge and icon styling on Routine Show and Edit pages by mapping missing colors to the primary palette.

### Fixed
- **AI Coach:** Resolved viewport freezing on routine generation by appending a `scrollIntoView` hook.
- **AI Coach:** Fixed "Content Missing" error on routine save by mapping the submission form to the `_top` Turbo frame.
- **AI Coach:** Corrected `load` parsing from Gemini and mapping to Database, replacing the default "Bodyweight" fallback.
- **AI Coach:** Prompt-engineered a token explosion fix to prevent Gemini from generating literal 130-day routines, enforcing 1-week microcycle limits for long-duration programs.
- **AI Coach:** Added flash alerts for JSON parsing failures and corrected path routing helper errors (`admin_new_ai_coach_path`).

### Added
- **Admin UI:** Implemented inline editing for `RoutineExercise` on the Routine Show page using Hotwire Turbo Frames.
- **Admin UI:** Added exercise name dropdowns for `sub_option_one` and `sub_option_two`.
### Added
- **API:** Google Sheets `sync_to_db` importer functionality for mapping Google Sheet columns directly into `RoutineExercise` records.
- **Database:** Fields `sub_option_one` and `sub_option_two` added to `RoutineExercise`.

### Changed
- **Database:** Dropped `rir`, `warmup`, `sub_option`, `instructions`, `substitutions`, and `rest` columns from `RoutineExercise`.
- **Integrations:** AI Coach Service payload and responses structured to cleanly support the new schema parameters.
- **Admin UI:** Displays for "Coach Instructions" and JSONB `substitutions` were replaced with strings corresponding to "Sub Option 1" and "Sub Option 2".

### Removed
- **Features:** Google Sheet `Export` feature, generation button, background Sidekiq jobs, and rendering `iframe` removed in favor of manual linking and automatic importing.
### Changed
- **UI:** Redesigned Sign Up and Log In pages with a responsive split-screen layout (image + form).
- **UI:** Updated auth forms to match Admin Panel aesthetic (colors, fonts).

### Added
- **Admin UI:** Daily Metric Modal for viewing detailed metric information from weekly/monthly calendars.
- **Admin UI:** Program Progress display showing current week and active routine on User Show page.

### Fixed
- **Admin UI:** Modal auto-open bug - modals no longer open automatically on page load.
- **Admin UI:** Modal hover bug - modals no longer open when hovering over metric links (disabled Turbo prefetch).
- **Admin UI:** Modal close functionality - added Escape key support and improved background click handling.

### Fixed
- **Admin UI:** Fixed Kaminari pagination rendering and styling across all admin collections.
- **Admin UI:** Solved `undefined method 'current_page'` errors by properly scoping `@pagy` or `kaminari` objects in controllers.
- **Styling:** Applied consistent pagination styles compatible with the dark/light theme.

### Added
- **Admin Dashboard:** Implemented dynamic data fetching for the User Growth chart (last 7 days).
- **Admin Dashboard:** Enhanced chart visualization with data labels, axis labels, and primary color branding.
- **Accessibility:** Added global focus rings for keyboard navigation.
- **Bug Fix:** Resolved `NameError: undefined local variable or method 'filters'` in Admin Index views.

### Added
- **Admin UI:** Comprehensive UI revamp for Daily Metrics, Dietary Plans, Exercises, Programs, Routines, Routine Exercises, and User Dietary Plans used consistently styled card tables.
- **Admin UI:** Implemented Turbo Frame-based modals for all CRUD operations (`new` and `edit` actions).
- **Admin UI:** Detailed `show` views for all core resources with context and stats.

### Changed
- **Admin UI:** Standardized design using Saffron/Graphite theme across all admin sections.
- **Refactor:** Removed legacy Coach Dashboard controller and views in favor of the unified Admin Panel.
- **Admin Dashboard**:
    - Migrated functionality from `Coach::DashboardsController` to `Admin::DashboardController`.
    - Integrated Flowbite Admin Dashboard with real-time stats (Active Clients, Low Compliance).
    - Added "Priority Inbox" for `CoachAlerts` and "Quick Actions" shortcuts.
- **Fixes**:
    - Resolved asset loading 404s by switching Flowbite/Popper.js to CDN bundles.
    - Fixed Admin Navigation links.
    - **Styling & Polish**:
        - Applied Saffron/Graphite custom theme (Tailwind v4).
        - Added Manual Dark Mode toggle (Stimulus controller + Tailwind custom variant).
        - Fixed broken icons by adding Material Symbols font.
        - Fixed broken icons by adding Material Symbols font.
        - Implemented mobile sidebar and user dropdown with custom Stimulus controllers.
    - **Hotwired Turbo Integration**:
        - Implemented Turbo Frames (`<turbo-frame id="admin_main_content">`) for persistent sidebar/navbar navigation without full reloads.
        - Added `data-turbo-action="advance"` to maintain URL history.
        - Implemented client-side active link highlighting with `active_link_controller.js`.
- **WhatsApp Ingestion (Integrations)**:
    - `Webhooks::WhatsappController` handling inbound messages from Twilio.
    - Natural Language Parsing: Messages are saved as `DailyMetric`, and AI extracts stats (Protein, Calories, etc.).
    - **Robust AI Service**: Refactored `GeminiService` to use `Net::HTTP` with SSL bypass (fixes local dev CRL errors).
- **Google Sheets Sync (Skeleton)**:
    - `Google::SheetsService` structure for writing programs to spreadsheets.
    - `ProvisionProgramSheetJob` for background creation.
    - Auto-provisioning callback on `Program` assignment.
- **Tech Stack**:
    - Added `twilio-ruby`, `google-apis-sheets_v4`, `googleauth`.
    - Generated `db/schema.sql` for Postgres DDL reference.

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

export $(grep -v '^#' .env | xargs) && bin/kamal deploy
