# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
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
