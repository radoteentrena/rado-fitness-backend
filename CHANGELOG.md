# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

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
