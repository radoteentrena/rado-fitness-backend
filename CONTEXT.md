# CONTEXT.md - Rado Fitness App

## 1. Project Overview
**Project Name:** Rado Fitness App
**Role:** Solo Developer
**Goal:** Build a scalable High-Ticket Fitness Coaching platform managed via a Ruby on Rails Admin Panel.
**Core Philosophy:** Automation of low-value tasks (data entry, basic feedback) via AI to allow high-touch human coaching for High Ticket clients.

## 2. Tech Stack (Rails 8 - 2026 Standards)
* **Framework:** Ruby on Rails 8.0
* **Database:** PostgreSQL
* **Background Jobs:** Solid Queue (Rails 8 default)
* **Caching:** Solid Cache (Rails 8 default)
* **CSS Framework:** TailwindCSS
* **Admin Framework:** **Avo** (v3+) - *This is the primary UI for the admin.*
* **Authentication:** Devise
* **AI Integration:** `langchainrb` (Gemini Adapter)
* **Soft Delete:** `discard` gem
* **HTTP Client:** `faraday`

## 3. Business Logic & Tiers
The app supports three tiers of service:

| Tier | Price | Key Features | AI Role |
| :--- | :--- | :--- | :--- |
| **Basic** | $10 | Standard Monthly Routine, Macro Targets. | None / Minimal. |
| **Medium** | $50 | Personalized Routine, Bi-weekly updates, Group Calls. | Routine drafting assistance. |
| **High Ticket** | $100 | Weekly Dynamic Planning, Priority Chat, Video Form Analysis, Biofeedback Audit. | Proactive analysis metrics, draft generation, WhatsApp parsing. |

### User Categorization (Internal)
Rado classifies clients to determine follow-up intensity:
*   **Soldado**: High activity, high compliance, needs close observation.
*   **Civil**: Maintenance mode, steady, less follow-up needed.
*   **Pelele**: Low activity/compliance, "just paying".

## 4. Workflows & Happy Paths

### Client Happy Path
1.  **Funnel**: Form -> Plan Selection -> Payment -> **User Created** (Admin Notified).
2.  **Onboarding**: "Alta de cliente" appears in Dashboard.
3.  **Scheduling (Medium/High)**: User books a call via **Google Calendar** integration.
4.  **Program Assignment**:
    *   Rado assigns a "Program" (duration + routines) using Templates.
    *   *Dietary Plan*: Tracked internally, user sees only Targets.
    *   **Delivery (MVP Phase)**: Program is delivered via **Google Sheets** (Bi-directional sync required for updates).
    *   User sees only the *Active Week* to ensure focus/progression.
5.  **Execution**:
    *   User logs weights/reps in the Sheet (or App view syncing to sheet).
    *   User sends Daily Macros via **WhatsApp Bot** -> Populates Admin Panel.

### Admin (Rado) Happy Path
1.  **Dashboard**:
    *   **Recent Activity**: Altas (New) / Bajas (Churn).
    *   **Calendar**: Upcoming calls/events.
    *   **Subs**: Active subscription monitoring.
2.  **Follow-up (Seguimiento)**:
    *   List users ordered by Category (Soldado > Civil > Pelele).
3.  **Client Profile**:
    *   Visual Progress Metrics (Week-over-Week).
    *   Routine Completion (from Sheet/App).
    *   Macro Compliance (from WhatsApp).
    *   Adjustments made here reflect in Client's Sheet/View.

## 4. Database Schema & Data Models

### User (Clients & Leads)
* **Fields:** `first_name`, `last_name`, `email`, `phone`, `status` (enum), `plan_tier` (enum), `category` (enum), `discarded_at`.
* **Enums:**
    * `status`: `{ lead: 0, active: 1, churned: 2, archived: 3 }`
    * `plan_tier`: `{ basic: 0, medium: 1, high_ticket: 2 }`
    * `category`: `{ pelele: 0, civil: 1, soldado: 2 }` (Ordered by priority)
* **Relationships:** `has_many :daily_metrics`, `has_one :nutrition_plan`, `has_many :programs`.

### DailyMetric (The Heart of Tracking)
* **Fields:** `date_logged`, `calories_consumed`, `protein_consumed`, `steps`, `weight`, `raw_message_content` (WhatsApp text), `compliant` (boolean), `ai_parsed_json`.
* **Logic:** Stores unstructured text from users; AI processes this to fill structured fields.

### Core Training Models (Refined by Mockup)
*   **Program**: Long-term goal (Macrocycle). Tracks progress (weeks).
    *   *Templates*: Base definitions.
    *   *Instances* (`user_program`): Assigned to user, has "current week" pointer.
*   **Routine** (Training Block/Mesocycle):
    *   Has `duration` (n weeks).
    *   Belongs to a Program.
*   **Workout** (Training Day):
    *   Belongs to a Routine.
    *   Has a `name` (e.g., "Leg Day").
*   **Exercise**: Library of movements (`muscle_group`, `video_url`).
*   **RoutineItem** (WorkoutExercise):
    *   Belongs to a Workout.
    *   Fields: `sets`, `reps`, `load`, `rir`, `rest`, `warmup` (bool), `sub_option` (variant).

### Nutrition & Progress
*   **DietaryPlan**: Template for nutrition targets.
*   **UserDietaryPlan**: Assigned instance.
    *   Fields: `calories_target`, `protein_target`, `notes`.
*   **DailyMetric**:
    *   Input: `raw_content` (WhatsApp).
    *   Parsed: `calories`, `protein`, `weight`.
    *   *Goal*: Normalize user input into this structured data.

## 5. Implementation Roadmap (Kanban)

### ✅ Completed
* Rails new (Postgres + Tailwind).
* Gemfile setup (`avo`, `devise`, `discard`, `langchainrb`).
* `User` model migration and configuration created.

### 🚧 In Progress: Epic 1 (Architecture) & Epic 2 (Avo)
1.  **Avo Resource Configuration:** Create resources for Users, Exercises.
2.  **Routine Logic:** Implement system to "Clone" a Template Routine to a specific Client.

### 📋 Todo: Epic 3 (AI Integration)
* **GeminiService:** Implement `app/services/gemini_service.rb` using `langchainrb`.
* **Parsing Logic:**
    * Input: "Ate 2 eggs and chicken breast"
    * Output: `{ "protein": 50, "calories": 400 }`
* **Feedback Logic:**
    * Input: Array of last 7 days metrics.
    * Output: "Weekly summary paragraph in Rado's tone."

### 📋 Todo: Epic 4 (Funnel & Payments)
* Public Onboarding Form (Lead Capture).
* Stripe Integration (Webhooks for status change `lead` -> `active`).

## 6. AI Integration Specifics (Gemini)
**Library:** We are using `langchainrb` (NOT `google_generative_ai` python lib, NOT `rubyllm`) for better JSON parsing and memory management.

**Service Pattern:**
```ruby
# app/services/gemini_service.rb wrapper pattern
class GeminiService
  def initialize
    @llm = Langchain::LLM::GoogleGemini.new(api_key: ENV['GEMINI_API_KEY'])
  end
  # Methods: parse_metrics(text), generate_weekly_feedback(metrics)
end
