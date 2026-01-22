AGENTS.md – Guidelines for automated agents operating in this repo

- This document provides structured build, lint, test commands and code‑style guidance tailored for the Rado Fitness Rails 8 app. The context here reflects the project docs found in CONTEXT.md, GEMINI.md, IDEAS.md and CHANGELOG.md.
- Cursor rules and Copilot rules: If present, apply them first. This repo currently has no explicit cursor or copilot rules in place.

1) Build, lint, and test commands
- Setup
  - Install dependencies: `bundle install` and `yarn install`
- Rails/db and assets
  - Prepare DB (dev): `bin/rails db:setup` (or `bin/rails db:create db:migrate`)
- Precompile assets
  - `RAILS_ENV=production bundle exec rails assets:precompile`
- Lint
  - Ruby/Rails: `bundle exec rubocop` (config in `.rubocop.yml` or similar)
  - Optional: JS/CSS lint (Tailwind) if configured: `yarn run eslint` / `yarn lint`
- Tests
  - Full test suite: `bundle exec rspec` (adjust if Minitest)
  - Run a single test by file and line: `bundle exec rspec path/to/file_spec.rb:LINE`
  - Run a single test by description: `bundle exec rspec path/to/file_spec.rb -e 'description'`
  - Run tests by tag: `bundle exec rspec --tag focus` or `bundle exec rspec -t focus`
  - Rails tests (Minitest): `bin/rails test` or `bin/rails test TEST=path/to/test_file.rb`
  - CI quick checks: `bundle exec rubocop --format simple` to surface lint errors separately from test failures

- Quick local workflow (one‑liner examples)
  - Setup + lint + test all in sequence (idempotent for CI):
    ```bash
    bundle install
    yarn install
    bin/rails db:setup
    bundle exec rubocop
    bundle exec rspec
    ```
  - Run a single test example by line: `bundle exec rspec spec/models/user_spec.rb:42`
  - If you need to bypass a failing example labeled with `xdescribe` or `xit`, align with your test strategy.

2) Code style guidelines
- General philosophy: Rails conventions + Ruby style guide. When in doubt, prefer readability and explicit intent. This aligns with the GEMINI.md guidance on minimal comments and the focus on domain models.
- File and imports
  - Use `require_relative` for intra‑project files; `require` for gems/stdlib. Place requires at the top, grouped by source: stdlib, external gems, internal.
  - Alphabetize within groups; separate groups with a single blank line.
  - Prefer eager loading of dependencies when clarity improves; avoid expensive requires in hot paths.
- Formatting and typography
  - 2 spaces per indentation; no tabs.
  - Frozen string literals: add `# frozen_string_literal: true` at the top where appropriate.
  - Line length: target 80–100 chars; wrap long calls gracefully.
  - End files with newline.
- Styles and naming
  - Classes/modules: CamelCase; e.g., `DailyMetric`, `NutritionPlan`.
  - Methods/variables: snake_case; e.g., `calculate_routing`, `user_id`.
  - Constants: ALL_CAPS with underscores.
  - File naming matches type: `app/services/metrics_parser.rb` defines `MetricsParser`.
  - Avoid overly long methods; extract to private helpers or domain objects.
- Error handling
  - Do not use bare `rescue`; rescue specific exceptions only.
  - When rescuing, log the error; re-raise only if the caller needs to know.
  - Use custom error classes under `app/errors` for domain errors.
- Architecture and responsibilities
  - Prefers thin models; move business logic to domain objects under `app/services` or `app/interactors` when appropriate. See GEMINI.md for guidance on avoiding generic Service Objects in favor of POROs that behave like models.
- Domain modeling guidance (per GEMINI.md)
  - Rich domain models; use `Concerns` for organization (app/models/concerns/).
  - Use POROs that behave like ActiveRecord models for domain concepts where needed.
- Services vs. Domain Objects
  - Avoid procedural Service Objects; prefer domain objects such as `Signup.new(params).save`.
- Controller and routing guidance (per GEMINI.md)
  - Strict REST; non-REST actions should live in dedicated controllers.
- Testing style (RSpec)
  - Describe/Context/It; deterministic tests; use FactoryBot; avoid testing private state.
- Security and secrets
  - Do not commit credentials; rely on Rails credentials or ENV.
- AI Integration (Gemini)
  - Implement `GeminiService` (see CONTEXT.md and IDEAS.md) as a wrapper around Langchain Ruby for AI parsing / feedback.
  - Use `ENV['GEMINI_API_KEY']` for Gemini access; parse JSON results carefully.
- CI/PR hygiene
  - Ensure rubocop and rspec pass in CI; keep PRs focused on domain changes.
- Testing examples continued
- AI and Gemini specifics
- 3) Context notes
- Context: The project uses Rails 8, Devise, Avo admin, Tailwind, and Gemini AI integration via `langchainrb`.
- See: CONTEXT.md, GEMINI.md, IDEAS.md, CHANGELOG.md for deeper guidance.
- 4) Cursor rules
- Cursor rules: none detected in this repository. If you add a policy later, document it here and reference the file path (e.g., `.cursor/rules/README.md`).
- 5) Copilot rules
- Copilot: none found in `.github/copilot-instructions.md`.
- 6) Backlog alignment
- Refer to IDEAS.md for backlog items (AI prompts, Gemini integration, metrics, and broadcast/QA features).

4) Cursor/Copilot rules
- Cursor rules: none detected in this repository. If you add a policy later, document it here and reference the file path (e.g., `.cursor/rules/README.md`).
- Copilot rules: none found in `.github/copilot-instructions.md`.

5) Context-driven recommendations
- Respect the architecture principles in GEMINI.md: keep domain logic in models/ POROs; minimize monolithic service objects; prefer explicit domain objects that resemble AR models.
- When implementing Gemini AI features, follow the patterns in CONTEXT.md and IDEAS.md: a `GeminiService` wrapper, JSON parsing, and a structured feedback generation flow.
- Tests should exercise domain behavior and AI integration endpoints, not internal scaffolding.
- Next steps: poke IDEAS backlog items, align with Epic 3 AI integration, and add/verify tests around GeminiService behavior.
