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

Add the following columns:

| Column | Type | Notes |
|---|---|---|
| `billing_type` | integer (enum) | `recurring: 0`, `one_time: 1`. Default: `recurring` |
| `frequency` | integer (enum) | `monthly: 0`, `quarterly: 1`, `yearly: 2`. Default: `monthly` |
| `access_expires_at` | datetime | Set for one-time payments; nil for recurring |
| `reminded_at` | datetime | Timestamp of last reminder sent; used to deduplicate |

### Migration: `users`

| Column | Type | Notes |
|---|---|---|
| `access_status` | integer (enum) | `active: 0`, `locked: 1`. Default: `active` |

---

## UI Flow

**Current:** Plan selection → checkout
**New:** Plan selection → **Frequency selector** → checkout

### Frequency Selector Screen

Displayed after the user picks a plan tier. Shows 4 radio card options. Plan tier is carried as a hidden param.

| Option | `billing_type` | `frequency` | Price displayed |
|---|---|---|---|
| Pago único (1 mes) | `one_time` | `monthly` | base price |
| Mensual | `recurring` | `monthly` | base price / mes |
| Trimestral | `recurring` | `quarterly` | (base × 3 × 0.95) / 3 — badge "5% off" |
| Anual | `recurring` | `yearly` | (base × 12 × 0.90) / 12 — badge "10% off" |

Submitting sends `plan_tier`, `billing_type`, and `frequency` to `SubscriptionsController#create`.

### Price Calculation (one-time)

```
amount = base_monthly_price × months × discount_multiplier
```

| Frequency | Months | Discount multiplier |
|---|---|---|
| monthly | 1 | 1.0 |
| quarterly | 3 | 0.95 |
| yearly | 12 | 0.90 |

Base prices are the existing monthly prices per plan tier (ARS or USD depending on `onboarding_profile.argentina?`).

---

## MercadoPago Integration

### Existing: `Subscriptions::MercadoPagoCheckout`

No changes. Handles `recurring` billing via `preapproval` API with plan IDs stored in credentials.

### New: `Subscriptions::MercadoPagoOneTimeCheckout`

- Receives: `user`, `plan_tier`, `frequency`
- Calculates total amount using the price table above
- Calls MP `preference` API (Checkout Pro)
- Returns `{ success:, redirect_url: }` — same interface as existing checkout
- Sets `access_expires_at = Time.current + months.months` after payment confirmed via webhook

### Controller routing

`SubscriptionsController#create` picks the service based on `billing_type`:

```ruby
if billing_type == "one_time"
  Subscriptions::MercadoPagoOneTimeCheckout.new(user, plan_tier, frequency).call
else
  Subscriptions::MercadoPagoCheckout.new(user, plan_tier, frequency).call
end
```

The recurring checkout will also be updated to pass `frequency` so the correct preapproval plan is used (quarterly and yearly plans will need their own MP plan IDs in credentials).

---

## Webhook Handling

### Existing: `subscription_preapproval` events

Already handled. Extended to:
- On `authorized`: set `user.access_status = :active`, clear `subscription.reminded_at`
- On `cancelled` / `paused`: update `subscription.status` accordingly

### New: `payment` events (Checkout Pro / one-time)

Added to `ProcessPaymentEventJob`:
- On `approved`: find subscription by `external_reference` (user ID), set `access_expires_at`, set `user.access_status = :active`
- On `rejected` / `cancelled`: log, no access change

---

## Background Job: `SubscriptionDunningJob`

Runs **daily** via cron.

### Queries

1. One-time subscriptions where `access_expires_at < Time.current` and `status != canceled`
2. Recurring subscriptions where `status = past_due`

### Dunning cadence

Calculates `days_overdue` from the due date (either `access_expires_at` or the date `status` became `past_due`).

| `days_overdue` | Action |
|---|---|
| 0 | Send WhatsApp + email reminder #1. Set `reminded_at = now` |
| 2 | Send WhatsApp + email reminder #2 |
| 4 | Send WhatsApp + email final warning |
| ≥ 5 | Set `user.access_status = :locked` |

Guard: the job only sends a reminder if `reminded_at` is nil or `reminded_at.to_date < today` — prevents duplicate sends on the same day.

### Channels

- **WhatsApp**: via existing `Webhooks::WhatsappController` infrastructure
- **Email**: via ActionMailer (`SubscriptionReminderMailer`)

---

## Access Locking

### Locking

`SubscriptionDunningJob` sets `user.access_status = :locked` at day 5.

### API enforcement

`ApplicationController` gains a `before_action :check_access_locked!` (applied to API endpoints):

```ruby
def check_access_locked!
  return unless current_user&.locked?
  render json: { error: "access_locked", payment_url: new_subscription_url }, status: :forbidden
end
```

The mobile frontend receives the 403, reads `payment_url`, and shows the locked screen with a redirect to payment.

### Unlocking

- **Recurring**: MP webhook fires `subscription_preapproval` with `authorized` → `user.access_status = :active`, clear `reminded_at`
- **One-time**: MP webhook fires `payment` with `approved` → set `access_expires_at`, `user.access_status = :active`

---

## Summary of Deliverables

| # | Deliverable |
|---|---|
| 1 | Migration: extend `subscriptions` (billing_type, frequency, access_expires_at, reminded_at) |
| 2 | Migration: add `access_status` to `users` |
| 3 | New view: frequency selector screen |
| 4 | Update `SubscriptionsController#create` to route by billing_type/frequency |
| 5 | New service: `Subscriptions::MercadoPagoOneTimeCheckout` |
| 6 | Update `ProcessPaymentEventJob` to handle `payment` events |
| 7 | New job: `SubscriptionDunningJob` with daily cron |
| 8 | New mailer: `SubscriptionReminderMailer` |
| 9 | `ApplicationController#check_access_locked!` before_action |
| 10 | Update MP recurring checkout to support quarterly/yearly frequencies |
