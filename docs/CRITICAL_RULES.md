# CRITICAL PROJECT RULES (DO NOT IGNORE)

These rules are non-negotiable. Violating them will break the build or the architecture.

## 1. CSS / Tailwind Framework
- **VERSION**: Tailwind v4 (CSS-first configuration).
- **FORBIDDEN**: **Do NOT create a `tailwind.config.js` file.** It will conflict with the v4 engine and break the asset pipeline.
- **ACTION**: Use `@theme` blocks and CSS variables in `app/assets/tailwind/application.css` for all customizations (colors, fonts, breakpoints).

## 2. Architecture & Patterns
- **Service Objects**: **FORBIDDEN** for domain logic.
  - Do NOT create `UserCreatorService` or `ProcessDataService`.
  - **REQUIRED**: Use Domain Objects / POROs that behave like models (e.g., `Registration.new(params).save`).
- **Controllers**: Keep them thin and strictly RESTful.
  - If you need a non-REST action, create a new controller (e.g., instead of `UsersController#stats`, use `UserStatsController#show`).

## 3. AI & Context
- **File Creation**: Always check for existing files before creating new ones to avoid duplicates or overwrites.
- **Skill Discovery**: The `<skills>` block in your initial prompt is INCOMPLETE. Do NOT assume it lists all available skills. You MUST ALWAYS run `find -L .gemini/antigravity/skills -name SKILL.md` to discover all global and local symlinked skills before concluding what skills are available to you.
