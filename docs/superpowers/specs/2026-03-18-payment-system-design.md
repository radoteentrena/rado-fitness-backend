# Payment System Design Spec
**Date:** 2026-03-18
**Status:** Approved for planning

---

## Overview

Dual-processor recurring subscription system for Rado Fitness. Argentine clients pay via MercadoPago in ARS; international clients (LatAm + US) pay via Stripe in USD. Both lanes converge into a unified `Subscription` model. Coach (Rado) is based in Argentina.

---

## Subscription Tiers

| Tier | USD Price | ARS Price |
|------|-----------|-----------|
| Basic | $10/mo | ARS equivalent (set manually in MP dashboard) |
| Medium | $50/mo | ARS equivalent |
| High Ticket | $100/mo | ARS equivalent |

ARS prices are set once in the MercadoPago dashboard when creating preapproval plans. Rado updates them manually when the exchange rate requires it.

---

## Architecture

Two parallel payment lanes with a single unified subscription state on `User`.

```
Onboarding Form (country field)
        │
        ├── Argentina ──► MercadoPago Subscriptions API (ARS)
        │                        │
        └── International ──► Stripe Subscriptions (USD)
                                  │
                           Both lanes
                                  │
                           Webhook handler
                           (Solid Queue job)
                                  │
                    Subscription record created/updated
                    User status: lead → active
```

**Processor routing:** Determined by `OnboardingProfile#country`. Set at subscription creation and never changed automatically. If a client changes country, Rado handles it manually from the admin panel.

**Gems:**
- `mercadopago-sdk` (`mercadopago-sdk` on RubyGems) — official MP Ruby SDK for Argentine lane
- `stripe-ruby` — Stripe Ruby SDK for international lane
- No `pay` gem — a unified custom `Subscription` model serves both processors cleanly

---

## Data Model

### New table: `subscriptions`

```ruby
create_table :subscriptions do |t|
  t.references :user,                  null: false, foreign_key: true
  t.integer    :processor,             null: false  # { stripe: 0, mercadopago: 1 }
  t.integer    :plan_tier,             null: false  # { basic: 0, medium: 1, high_ticket: 2 }
  t.integer    :status,                null: false, default: 0
  # { pending: 0, active: 1, past_due: 2, canceled: 3 }
  t.string     :external_id           # Stripe subscription ID or MP preapproval subscription ID
  t.string     :external_customer_id  # Stripe customer ID or MP payer ID
  t.string     :external_plan_id      # Stripe price ID or MP preapproval plan ID
  t.string     :currency,             default: 'USD'
  t.integer    :amount_cents
  t.datetime   :current_period_end
  t.boolean    :cancel_at_period_end,  default: false
  t.datetime   :canceled_at
  t.timestamps
end
```

**Indexes:** `user_id`, `status`, `processor`

**One subscription per user:** Enforced at the model level (`validates :user_id, uniqueness: true`), not via a unique DB index. This allows `find_or_initialize_by(user: user)` in the webhook job so that a churned user who resubscribes updates the existing record in place rather than creating a new row that would violate a DB constraint.

### Associations

```ruby
User has_one :subscription
Subscription belongs_to :user
```

### MercadoPago preapproval plan IDs

The three plan IDs (one per tier, created once in the MP dashboard) are stored in Rails credentials — no DB table needed.

```yaml
# credentials.yml
mercadopago:
  access_token: ...
  webhook_secret: ...
  plans:
    basic: "plan_xxx"
    medium: "plan_yyy"
    high_ticket: "plan_zzz"
```

### OnboardingProfile change

Add `country` string field (ISO 3166-1 alpha-2, e.g., `"AR"`, `"US"`, `"CL"`). Required. Collected as a dropdown in the existing multi-step onboarding form.

### User status side effects

| Subscription event | User#status change | CoachAlert |
|---|---|---|
| Subscription activated | `lead → active` | — |
| Payment failed | stays `active` (grace period) | `payment_failed` |
| Subscription canceled | `active → churned` | — |

---

## Checkout Flows

### Stripe (international)

1. User completes onboarding form with non-AR country
2. `SubscriptionsController#create` instantiates `Subscriptions::StripeCheckout`
3. PORO creates Stripe Customer + Checkout Session (hosted)
4. User redirected to Stripe-hosted checkout
5. On return: optimistic "processing" page shown
6. Webhook confirms asynchronously → `Subscription` created, `User → active`

### MercadoPago (Argentina)

1. User completes onboarding form with `country: "AR"`
2. `SubscriptionsController#create` instantiates `Subscriptions::MercadoPagoCheckout`
3. PORO fetches preapproval plan ID from credentials, creates subscription link via `mercadopago-sdk`
4. User redirected to MP-hosted checkout
5. On return: optimistic "processing" page shown
6. Webhook confirms asynchronously → `Subscription` created, `User → active`

### Domain objects (POROs)

Both implement the same interface:

```ruby
Subscriptions::StripeCheckout.new(user, plan_tier).call
# => { success: true, redirect_url: "https://checkout.stripe.com/..." }

Subscriptions::MercadoPagoCheckout.new(user, plan_tier).call
# => { success: true, redirect_url: "https://www.mercadopago.com.ar/..." }
```

The controller selects the PORO based on `user.onboarding_profile.country == "AR"`.

### Success/cancel routes

```
GET /subscriptions/success  → SubscriptionsController#success (optimistic "processing" state)
GET /subscriptions/cancel   → SubscriptionsController#cancel  (return to plan selection)
```

---

## Webhook Handling

### New controllers

```
Webhooks::StripeController       POST /webhooks/stripe
Webhooks::MercadopagoController  POST /webhooks/mercadopago
```

Both skip CSRF, verify authenticity, enqueue a job, return `200` immediately.

### Stripe events

| Event | Action |
|-------|--------|
| `checkout.session.completed` | Create `Subscription`, `User → active` |
| `invoice.payment_succeeded` | Update `subscription.current_period_end` |
| `invoice.payment_failed` | `Subscription → past_due`, create `CoachAlert` |
| `customer.subscription.deleted` | `Subscription → canceled`, `User → churned` |

Verification: `Stripe::Webhook.construct_event` with webhook signing secret from credentials.

### MercadoPago notifications

| Notification topic | Status / condition | Action |
|---|---|---|
| `preapproval` | `authorized` | Create `Subscription`, `User → active` |
| `preapproval` | `cancelled` | `Subscription → canceled`, `User → churned` |
| `payment` (subscription charge) | status `rejected` | `Subscription → past_due`, create `CoachAlert` |

> **Implementation note:** Payment failures for recurring subscriptions surface via the `payment` notification topic, not as a `preapproval` status change. The webhook handler must listen for both `preapproval` and `payment` topic types and route accordingly.

Verification: MercadoPago notification API v2 (HMAC-SHA256 `x-signature` header). The webhook URL includes a `?secret=...` query param as a secondary check, but the primary verification uses the header signature against the secret stored in credentials. This matches MP's current recommended approach for preapproval webhooks.

### Processing job

```ruby
ProcessPaymentEventJob < ApplicationJob
  # Receives processor, event_type, payload
  # Finds or creates Subscription
  # Updates User status
  # Creates CoachAlert if needed
```

---

## New CoachAlert Category

Add `payment_failed` to `CoachAlert` enum alongside existing values (`missed_workout`, `low_compliance`, `weight_spike`, `check_in`, `program_complete`).

---

## Admin UI

### User show page — new Subscription section

Displays: status badge, plan tier, processor, next billing date, amount + currency, and a "Cancelar al vencimiento" button.

"Cancelar al vencimiento" sets `cancel_at_period_end: true` on both the processor and the `Subscription` record. Client retains access until `current_period_end`, then churns via webhook.

Cancellation handled by: `Admin::SubscriptionCancellationsController#create` — delegates to `Subscriptions::Cancellation` PORO that calls the correct processor API.

### Administrate: Subscriptions dashboard

New `SubscriptionDashboard` in the admin sidebar. Columns: client name, plan, processor, status, next billing date. Filterable by `status` and `processor`.

### CoachAlert integration

Payment failure alerts surface automatically in the existing Priority Inbox on the admin dashboard. No additional UI work required.

---

## Out of Scope (this iteration)

- Plan upgrades/downgrades (involves proration logic)
- Refunds (handled manually via MP/Stripe dashboards)
- Free trials
- Coach manually moving a client between processors
- Coupon/discount codes

---

## Key Invariants

1. A `User` has at most one `Subscription` record.
2. Processor is determined at checkout and never changed automatically.
3. `User#status` is always the source of truth for access — `Subscription` is the payment layer beneath it.
4. Webhook handlers never block — they enqueue and return `200`.
5. The success page is always optimistic — subscription state is confirmed only via webhook.
