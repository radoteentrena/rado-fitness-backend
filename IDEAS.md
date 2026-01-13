# Research & Inspiration: Harbiz Analysis

**Source:** [Harbiz.io](https://app.harbiz.io/home-profesional)
**Date:** 2026-01-12

## 💎 Key Concepts for Rado Fitness

### 1. Dual Compliance Metrics (Crucial for High Ticket)
Harbiz distinguishes between two types of compliance. We should echo this:
*   **S% (Session Compliance):** Did they do the workout?
*   **M% (Metric Compliance):** Did they log their weight/macros?
> *Application:* For our High Ticket tier, **M%** is often more important than S%. We should highlight this in the Admin Panel User List.

### 2. Dashboard Logic
*   **"Feed" Style Activity:** Instead of just static tables, a temporal feed ("Juan uploaded a video", "Maria missed a workout") makes the coach feel connected.
*   **Quick Actions Iconography:** Simple, bold icons for "Add Client", "Create Workout", "Chat".

### 3. Workout Builder UX
*   **Mobile Preview Toggle:** A button to immediately see how the block/superset looks on a narrow screen.
*   **Prompt-to-Workout:** They have a text box to generate routines. *We are already planning this with Gemini, but seeing it confirms it's a winning feature.*
*   **Simple vs. Standard Mode:** Distinguishing between a "Grocery List" of exercises (Low Friction) and "Periodized Blocks" (High Precision).

### 4. Communication
*   **Mass Blast:** Ability to filter clients (e.g., "All Active") and send a broadcast message.
*   **Quick Replies:** Saved snippets for common feedback.

## 🎨 UI/Design Pattern Inspirations
*   **Tagging System:** Colorful pills in the client list for quick categorization (e.g., "Objective: Hypertrophy", "Risk: High").
*   **Clean Hierarchy:** The side nav is grouped deeply but intuitively (Community, Content, Business).
*   **Green/Red Indicators:** Heavy use of simple visuals to denote status (Compliance) without reading numbers.

## 🚀 Actionable Backlog Items
1.  **Modify User Model:** Ensure we can calculate `metric_compliance` separate from `routine_compliance`.
2.  **Admin UI:** In Avo, customize the User Index to show these two % metrics as visual bars.
3.  **Chat:** Implement "Broadcast" feature in `MessagesController`.
4.  **AI Builder:** Ensure our Gemini prompt can handle "Simple List" requests vs "Detailed Block" requests.
