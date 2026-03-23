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

**Change `User` association** from `has_one :subscription, dependent: :destroy` to `has_many :subscriptions, dependent: :destroy`. Add a deterministic convenience scope:

```ruby
# user.rb
has_many :subscriptions, dependent: :destroy

def active_subscription
  subscriptions.where(status: [:pending, :active]).order(created_at: :desc).first
end
```

`order(created_at: :desc)` ensures the most recently created record wins when multiple pending/active rows exist during a transition. All existing call sites of `user.subscription` must be updated to `user.active_subscription`.

The existing `find_or_initialize_by(user: user)` in the `mercadopago_preapproval` webhook branch must be updated to use `first_or_initialize` (which supports array scopes):

```ruby
Subscription.where(user: user, billing_type: :recurring, status: [:active, :pending]).first_or_initialize
```

Add the following columns:

| Column | Type | Notes |
|---|---|---|
| `billing_type` | integer (enum) | `recurring: 0`, `one_time: 1`. Default: `recurring` |
| `frequency` | integer (enum) | `monthly: 0`, `quarterly: 1`, `yearly: 2`. Default: `monthly` |
| `access_expires_at` | datetime | Set on webhook `approved` for one-time payments; nil for recurring |
| `reminded_at` | datetime | Updated after each reminder send; used for idempotency |
| `past_due_since` | datetime | Set when `status` transitions to `past_due`; used by dunning job |
| `mp_preference_id` | string | Stores MP `preference.id` for one-time Checkout Pro payments |

**Model validation:** `billing_type: one_time` is only valid with `frequency: monthly`.

```ruby
validates :frequency, inclusion: { in: [:monthly] }, if: -> { one_time? }
```

### Migration: `users`

| Column | Type | Notes |
|---|---|---|
| `access_status` | integer (enum) | `active: 0`, `locked: 1`. Default: `active` |

---

## UI Flow

**Current:** Plan selection (`GET /subscriptions/new`) → `POST /subscriptions`
**New:** Plan selection → Frequency selector → `POST /subscriptions`

### Routes

Two separate controller actions for the two screens. The existing routes use singular paths (`subscription/new`, `subscription`), so the new route follows the same convention:

- `GET /subscription/new` — plan selector (existing, no change)
- `GET /subscription/frequency?plan_tier=basic` — frequency selector (new action: `frequency`)
- `POST /subscription` — checkout (existing `create` action, extended)

The plan selector form uses `method: :get` and `action: subscription_frequency_path` so that `plan_tier` is passed as a query param. The frequency selector displays the 4 options with `plan_tier` as a hidden field, then POSTs to `subscription_path`.

`new_subscription_url` (pointing to the plan selector) remains the correct recovery URL for locked users.

### URL helper in API context

`check_access_locked!` uses `new_subscription_url`. `default_url_options` must be configured in `Api::V1::BaseController` (or inherited from `ApplicationController`) with `host: Rails.application.credentials.dig(:app_host)` to prevent a missing-host error.

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
    # Preapproval-related payment (existing logic, guard kept here)
    return unless payment["status"] == "rejected"
    # ... existing past_due logic ...
    sub.past_due!
    sub.update!(past_due_since: Time.current)  # write past_due_since here
  else
    handle_checkout_pro_payment(payment)
  end
```

**`handle_checkout_pro_payment`** (new private method):
- Look up `Subscription` using `find_by(mp_preference_id: payment["preference_id"])`
- If no record found: log a warning and return (do not raise — avoids job retry loops for unrecognized preference IDs)
- On `approved`: `subscription.update!(access_expires_at: Time.current + 1.month, status: :active)`, `user.active!` (sets `user.status = :active`, matching the existing preapproval `authorized` behavior), and `user.update!(access_status: :active)`. No `CoachAlert` is created for one-time payments.
- On `rejected` / `cancelled`: log only, no access change, no `CoachAlert`

### `ProcessPaymentEventJob` — `subscription_preapproval` branch

Extended additively:
- On `authorized`: set `user.access_status = :active` (in addition to existing `user.active!`), clear `subscription.reminded_at`, clear `subscription.past_due_since`. The `assign_attributes` call must explicitly include `billing_type: :recurring` to ensure newly initialized records have the correct value before `save!`.
- On `"cancelled"` (MP string, two `l`s): update `subscription.status = :canceled` (enum key, one `l`) — existing behavior, no change
- On `paused`: update `subscription.status` accordingly

---

## Background Job: `SubscriptionDunningJob`

Runs **daily** via cron.

### Queries

1. One-time subscriptions: `billing_type: :one_time`, `status: :active`, `access_expires_at < Time.current`
2. Recurring subscriptions: `billing_type: :recurring`, `status: :past_due`

Scoping one-time to `status: :active` ensures abandoned `pending` records (checkout never completed) are never dunned. One-time subscriptions **do not transition to `past_due`** — the `past_due` status is only set by the preapproval webhook branch which applies to recurring only. One-time subscriptions remain in `status: :active` throughout the dunning period (days 0–4) and are only removed from the dunning query when the user pays (webhook sets a new `access_expires_at`) or the subscription is `canceled`.

### `days_overdue` calculation

- **One-time**: `(Date.current - subscription.access_expires_at.to_date).to_i`
- **Recurring**: `(Date.current - subscription.past_due_since.to_date).to_i`

`past_due_since` is guaranteed non-nil for any recurring subscription in `past_due` status because it is written at the `sub.past_due!` call in `ProcessPaymentEventJob`.

### Dunning cadence

| `days_overdue` | Action | Updates `reminded_at`? |
|---|---|---|
| 0 | Send WhatsApp + email reminder #1 | Yes |
| 2 | Send WhatsApp + email reminder #2 | Yes |
| 4 | Send WhatsApp + email final warning | Yes |
| ≥ 5 | Set `user.access_status = :locked` | — |

### Guard logic (idempotency)

Before sending any reminder, the job checks **both**:

1. `days_overdue` is exactly 0, 2, or 4
2. `reminded_at.nil? || reminded_at.to_date < Date.current`

Both must pass. Condition 1 prevents sends on intermediate days (1 or 3). Condition 2 prevents duplicate sends on the same calendar day after retries. `reminded_at` is updated to `Time.current` after every successful send.

### Channels

- **WhatsApp**: via existing WhatsApp messaging infrastructure
- **Email**: via ActionMailer (`SubscriptionReminderMailer`)

---

## Access Locking

### Locking

`SubscriptionDunningJob` sets `user.access_status = :locked` when `days_overdue >= 5`.

### API enforcement

`Api::V1::BaseController` gains a `before_action :check_access_locked!`:

```ruby
def check_access_locked!
  return unless current_user&.locked?
  render json: { error: "access_locked", payment_url: new_subscription_url }, status: :forbidden
end
```

`default_url_options` must include `host: Rails.application.credentials.dig(:app_host)` in this controller. Web and admin controllers are unaffected.

### Unlocking

- **Recurring**: `subscription_preapproval` with `authorized` → `user.access_status = :active` (alongside `user.active!`), clear `reminded_at`, clear `past_due_since`
- **One-time**: `payment` with `approved` (Checkout Pro branch) → `access_expires_at = Time.current + 1.month`, `status = :active`, `user.access_status = :active`

---

## Summary of Deliverables

| # | Deliverable |
|---|---|
| 1 | Migration: extend `subscriptions` (billing_type, frequency, access_expires_at, reminded_at, past_due_since, mp_preference_id); remove DB uniqueness on user_id |
| 2 | Migration: add `access_status` to `users` |
| 3 | Update `User`: `has_one` → `has_many :subscriptions, dependent: :destroy`; add `active_subscription` scope; update all call sites |
| 4 | New controller action `SubscriptionsController#frequency` + route `GET /subscriptions/frequency` |
| 5 | New view: frequency selector screen |
| 6 | Update `SubscriptionsController#create` to route by billing_type/frequency |
| 7 | New service: `Subscriptions::MercadoPagoOneTimeCheckout` |
| 8 | Refactor `ProcessPaymentEventJob#mercadopago_payment`: relocate guard inside preapproval branch; add Checkout Pro branch; write `past_due_since` on `past_due!` |
| 9 | Update `ProcessPaymentEventJob#mercadopago_preapproval`: write `user.access_status`, clear `reminded_at` and `past_due_since` on `authorized` |
| 10 | Update `Subscriptions::MercadoPagoCheckout` to route frequency to correct plan ID |
| 11 | Add 9 quarterly/yearly plan IDs to credentials |
| 12 | New job: `SubscriptionDunningJob` with daily cron |
| 13 | New mailer: `SubscriptionReminderMailer` |
| 14 | `Api::V1::BaseController#check_access_locked!` + `default_url_options` configuration |
| 15 | Model validation: `one_time` billing_type only valid with `monthly` frequency |
