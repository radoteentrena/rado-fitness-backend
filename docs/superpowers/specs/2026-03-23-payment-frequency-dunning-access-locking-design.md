# Payment Frequency, Dunning & Access Locking — Design Spec

**Date:** 2026-03-23
**Status:** Approved
**Branch:** feature/payment-system

---

## Overview

Extend the existing MercadoPago payment system to support one-time payments alongside recurring subscriptions, add a dunning flow with WhatsApp + email reminders, and lock platform access for users who don't pay within 5 days of their due date.

---

## Context

Currently, the app only supports monthly recurring subscriptions via MercadoPago's `preapproval` API. The coach wants to offer customers the flexibility of one-time payments (no auto-renewal). Additionally, there is no automated reminder or access-control mechanism when payments are missed.

---

## Spelling convention

Throughout this spec and all implementation code:
- Rails enum key: `:canceled` (one `l`)
- MP API webhook event string: `"cancelled"` (two `l`s) — do **not** change these string matches

---

## Scope

1. Payment frequency selector UI (between plan selection and checkout)
2. One-time payment checkout via MP Checkout Pro (`preference` API)
3. Data model extensions to `subscriptions` and `users`
4. Webhook handling for `payment` events (one-time)
5. Background dunning job with WhatsApp + email reminders
6. Access locking via `user.access_status`

---

## Data Model Changes

### Migration: `subscriptions`

**Remove** the `validates :user_id, uniqueness: true` constraint. A user may have multiple subscription records over time. Only one subscription should be `active` or `pending` at a time — enforced at the application layer.

**Change `User` association** from `has_one :subscription, dependent: :destroy` to `has_many :subscriptions, dependent: :destroy`. Add the new enum and convenience scope:

```ruby
# user.rb
has_many :subscriptions, dependent: :destroy

# Use prefix: :access to avoid collision with existing `enum :status` which also
# generates `active!` and `active?`. With prefix, methods become:
# user.access_active!, user.access_locked!, user.access_active?, user.access_locked?
enum :access_status, { active: 0, locked: 1 }, default: :active, prefix: :access

def active_subscription
  subscriptions.where(status: [:pending, :active]).order(created_at: :desc).first
end
```

The existing `user.active!` (which sets `status = :active` from the `enum :status` declaration) is **not affected** by adding the new enum with `prefix: :access`. Do not call `user.active!` to unlock access — call `user.access_active!` instead.

All existing call sites of `user.subscription` must be updated to `user.active_subscription`. Known call sites to update:
- `app/controllers/subscriptions_controller.rb`
- `app/controllers/webhooks/mercadopago_controller.rb` (via `ProcessPaymentEventJob`)
- `app/views/admin/users/show.html.erb` (renders the subscription partial with `user.subscription`)
- Any other views or presenters referencing `user.subscription`

The existing `find_or_initialize_by(user: user)` in the `mercadopago_preapproval` webhook branch must be updated to:

```ruby
sub = Subscription.where(user: user, billing_type: :recurring, status: [:active, :pending])
                  .first_or_initialize
```

`first_or_initialize` auto-assigns equality conditions (`billing_type: :recurring`) on a new record but does **not** auto-assign array conditions (`status: [:active, :pending]`). The subsequent `assign_attributes` call must therefore explicitly set `status`, `billing_type: :recurring`, and all other required fields.

When a new subscription payment is approved, cancel all previous subscription records for that user before granting access. Only run this step if the record is persisted (i.e., `subscription.persisted?`) — skip if it is a brand-new unsaved record (first-time subscriber) to avoid the `WHERE id IS NOT NULL` condition that would cancel all existing records:

```ruby
if subscription.persisted?
  user.subscriptions.where.not(id: subscription.id).update_all(status: :canceled)
end
```

This prevents stale `active` records from appearing in future dunning queries.

Add the following columns. All integer columns must be `null: false, default: 0` so existing rows get a valid value immediately without a backfill:

| Column | Type | Migration options | Notes |
|---|---|---|---|
| `billing_type` | integer (enum) | `null: false, default: 0` | `recurring: 0`, `one_time: 1` |
| `frequency` | integer (enum) | `null: false, default: 0` | `monthly: 0`, `quarterly: 1`, `yearly: 2` |
| `access_expires_at` | datetime | `null: true` | Set on webhook `approved` for one-time; nil for recurring |
| `reminded_at` | datetime | `null: true` | Updated after each reminder send |
| `past_due_since` | datetime | `null: true` | Set on `past_due` transition |
| `mp_preference_id` | string | `null: true` | MP `preference.id` for Checkout Pro payments |

**Model validation:** `billing_type: one_time` is only valid with `frequency: monthly`.

```ruby
validates :frequency, inclusion: { in: [:monthly] }, if: -> { one_time? }
```

### Migration: `users`

Add `access_status` as a non-null integer with DB default `0`:

```ruby
add_column :users, :access_status, :integer, null: false, default: 0
```

This ensures all existing rows get `access_status = 0` (`:active`) immediately without a separate backfill step. No data migration needed.

---

## UI Flow

**Current:** Plan selection (`GET /subscription/new`) → `POST /subscription`
**New:** Plan selection → Frequency selector → `POST /subscription`

### Routes

Add to `config/routes.rb`:

```ruby
get "subscription/frequency", to: "subscriptions#frequency", as: :subscription_frequency
```

Full route set:
- `GET /subscription/new` — plan selector (existing `new` action; helper: `new_subscription_path`)
- `GET /subscription/frequency` — frequency selector (new `frequency` action; helper: `subscription_frequency_path`)
- `POST /subscription` — checkout (existing `create` action; helper: `subscription_path`)

The plan selector form uses `method: :get` pointing to `subscription_frequency_path` so that `plan_tier` is appended as a query param. The frequency selector displays the 4 options with `plan_tier` as a hidden field, then POSTs to `subscriptions_path` (the existing plural helper that maps to `POST /subscription`).

`new_subscription_url` (pointing to the plan selector) is the recovery URL for locked users.

### URL helpers in API context

`Api::V1::BaseController` inherits from `ActionController::API` and does not include URL helpers automatically. Add:

```ruby
include Rails.application.routes.url_helpers

def default_url_options
  { host: Rails.application.credentials.dig(:app_host) }
end
```

### Frequency Selector Screen

| Option | `billing_type` | `frequency` | Price displayed |
|---|---|---|---|
| Pago único (1 mes) | `one_time` | `monthly` | base price (no badge) |
| Mensual | `recurring` | `monthly` | base price / mes |
| Trimestral | `recurring` | `quarterly` | (base × 3 × 0.95) / 3 — badge "5% off" |
| Anual | `recurring` | `yearly` | (base × 12 × 0.90) / 12 — badge "10% off" |

### Price Calculation

```
amount = base_monthly_price × months × discount_multiplier
```

| `billing_type` / `frequency` | Months | Discount multiplier |
|---|---|---|
| one_time / monthly | 1 | 1.0 |
| recurring / monthly | — | — (MP plan handles billing) |
| recurring / quarterly | 3 | 0.95 |
| recurring / yearly | 12 | 0.90 |

Base prices are the existing monthly prices per plan tier (ARS or USD depending on `onboarding_profile.argentina?`).

---

## MercadoPago Integration

### Existing: `Subscriptions::MercadoPagoCheckout`

Handles `recurring` billing via `preapproval` API. Extended to accept `frequency` and route to the correct plan ID. New credentials structure:

```yaml
mercadopago:
  plans:
    basic_monthly: "..."
    basic_quarterly: "..."
    basic_yearly: "..."
    medium_monthly: "..."
    medium_quarterly: "..."
    medium_yearly: "..."
    high_ticket_monthly: "..."
    high_ticket_quarterly: "..."
    high_ticket_yearly: "..."
```

### New: `Subscriptions::MercadoPagoOneTimeCheckout`

- Receives: `user`, `plan_tier`, `frequency` (always `monthly`)
- Calculates total amount: `base_monthly_price × 1 × 1.0`
- Calls MP `preference` API (Checkout Pro)
- Stores `mp_preference_id` on the `Subscription` record immediately (before redirect)
- Returns `{ success:, redirect_url: }` — same interface as existing checkout
- Does **not** set `access_expires_at` — set by webhook on payment confirmation

### Controller routing

```ruby
if billing_type == "one_time"
  Subscriptions::MercadoPagoOneTimeCheckout.new(user, plan_tier, frequency).call
else
  Subscriptions::MercadoPagoCheckout.new(user, plan_tier, frequency).call
end
```

---

## Webhook Handling

### `ProcessPaymentEventJob` — `payment` branch refactor

The existing guard `return unless payment["status"] == "rejected"` must be **removed from its top-level position** and relocated **inside the preapproval branch only**. The branch now discriminates on `metadata.preapproval_id`:

```ruby
when "payment"
  if payment.dig("metadata", "preapproval_id").present?
    # Preapproval-related payment (existing logic, guard relocated here)
    return unless payment["status"] == "rejected"
    # ... existing past_due logic ...
    sub.past_due!
    sub.update!(past_due_since: Time.current)
  else
    handle_checkout_pro_payment(payment)
  end
```

**`handle_checkout_pro_payment`** (new private method):

The MP Checkout Pro payment object includes a `"preference_id"` key at the top level of the payment hash. **Implementer must verify this key name against the actual MP SDK response** before shipping — log the full payload on the first test payment to confirm.

- Look up `Subscription` using `find_by(mp_preference_id: payment["preference_id"])`
- If no record found: log a warning and return (do not raise — avoids retry loops for unrecognized preference IDs)
- On `approved`:
  - Cancel other subscriptions first: `user.subscriptions.where.not(id: subscription.id).update_all(status: :canceled)`
  - `subscription.update!(access_expires_at: Time.current + 1.month, status: :active)`
  - `user.active!` (sets `user.status = :active`)
  - `user.access_active!` (sets `user.access_status = :active` via prefixed enum method)
  - No `CoachAlert` created
- On `rejected` / `cancelled`: log only, no access change, no `CoachAlert`

### `ProcessPaymentEventJob` — `subscription_preapproval` branch

Extended additively:
- On `authorized`:
  - Cancel other subscriptions first: `user.subscriptions.where.not(id: sub.id).update_all(status: :canceled)`
  - Set `user.access_active!` (in addition to existing `user.active!` which sets `user.status`)
  - Clear `sub.reminded_at` and `sub.past_due_since`
  - `assign_attributes` must explicitly include `billing_type: :recurring` and `status: :active`
- On `"cancelled"` (MP string, two `l`s): set `subscription.status = :canceled` (existing behavior which calls `user.churned!`); additionally call `user.access_locked!` so the user loses API access immediately rather than waiting for the dunning job
- On `"paused"` (MP string): log only — no `paused` value in the `Subscription` status enum, do not attempt to write it

---

## Background Job: `SubscriptionDunningJob`

Runs **daily** via cron.

### Queries

1. One-time: `Subscription.where(billing_type: :one_time, status: :active).where("access_expires_at < ?", Time.current)`
2. Recurring: `Subscription.where(billing_type: :recurring, status: :past_due)`

One-time subscriptions remain `status: :active` throughout the dunning period (days 0–4). At `days_overdue >= 5`, after locking the user, the job also sets `subscription.update!(status: :canceled)` on the one-time subscription. This removes it from future dunning queries and provides a clear terminal state. The `update_all(status: :canceled)` on payment approval ensures stale records from previous cycles are also excluded.

### `days_overdue` calculation

- **One-time**: `(Date.current - subscription.access_expires_at.to_date).to_i`
- **Recurring**: `(Date.current - subscription.past_due_since.to_date).to_i`

### Dunning cadence

| `days_overdue` | Action | Updates `reminded_at`? |
|---|---|---|
| 0 | Send WhatsApp + email reminder #1 | Yes |
| 2 | Send WhatsApp + email reminder #2 | Yes |
| 4 | Send WhatsApp + email final warning | Yes |
| ≥ 5 | `user.access_locked!` | — |

### Guard logic (idempotency)

Before sending any reminder, the job checks **both**:

1. `days_overdue` is exactly 0, 2, or 4
2. `reminded_at.nil? || reminded_at.to_date < Date.current`

Both must pass. `reminded_at` is updated to `Time.current` after each send.

### Channels

- **WhatsApp**: via existing WhatsApp messaging infrastructure
- **Email**: via ActionMailer (`SubscriptionReminderMailer`)

---

## Access Locking

### Locking

`SubscriptionDunningJob` calls `user.access_locked!` when `days_overdue >= 5`.

### API enforcement

`Api::V1::BaseController` — add after existing `before_action :authenticate_user!`:

```ruby
include Rails.application.routes.url_helpers

before_action :authenticate_user!
before_action :check_access_locked!

def default_url_options
  { host: Rails.application.credentials.dig(:app_host) }
end

def check_access_locked!
  return unless current_user.access_locked?
  render json: { error: "access_locked", payment_url: new_subscription_url }, status: :forbidden
end
```

`check_access_locked!` runs after `authenticate_user!`, so `current_user` is always present. Web and admin controllers are unaffected.

### Unlocking

- **Recurring**: `subscription_preapproval` `authorized` → `user.active!` + `user.access_active!`, clear `reminded_at` and `past_due_since`
- **One-time**: `payment` `approved` (Checkout Pro branch) → `user.active!` + `user.access_active!`, `access_expires_at = Time.current + 1.month`

---

## Summary of Deliverables

| # | Deliverable |
|---|---|
| 1 | Migration: extend `subscriptions` (billing_type, frequency, access_expires_at, reminded_at, past_due_since, mp_preference_id); remove DB uniqueness on user_id |
| 2 | Migration: `add_column :users, :access_status, :integer, null: false, default: 0`; add `enum :access_status, { active: 0, locked: 1 }, default: :active, prefix: :access` to `user.rb` |
| 3 | Update `User`: `has_one` → `has_many :subscriptions, dependent: :destroy`; add `active_subscription` scope; update all call sites including `app/views/admin/users/show.html.erb` |
| 4 | Add route `get "subscription/frequency", to: "subscriptions#frequency", as: :subscription_frequency`; new `SubscriptionsController#frequency` action |
| 5 | New view: frequency selector screen |
| 6 | Update `SubscriptionsController#create` to route by `billing_type`/`frequency` |
| 7 | New service: `Subscriptions::MercadoPagoOneTimeCheckout` |
| 8 | Refactor `ProcessPaymentEventJob#mercadopago_payment`: relocate guard inside preapproval branch; add Checkout Pro branch; write `past_due_since` on `past_due!`; cancel other subscriptions on approval; verify `payment["preference_id"]` key against MP SDK |
| 9 | Update `ProcessPaymentEventJob#mercadopago_preapproval`: call `user.access_active!` on `authorized`; add `billing_type: :recurring` and `status: :active` to `assign_attributes`; cancel other subscriptions; log-only for `paused` |
| 10 | Update `Subscriptions::MercadoPagoCheckout` to route frequency to correct plan ID |
| 11 | Add 9 plan IDs to credentials (basic/medium/high_ticket × monthly/quarterly/yearly) |
| 12 | New job: `SubscriptionDunningJob` with daily cron |
| 13 | New mailer: `SubscriptionReminderMailer` |
| 14 | `Api::V1::BaseController`: include `url_helpers`, `default_url_options`, `check_access_locked!` after `authenticate_user!` |
| 15 | Model validation: `one_time` billing_type only valid with `monthly` frequency |
