# Plan Selection Page — Design Spec

## Goal

Replace the current `subscriptions/new` view (which shows the user's pre-assigned plan) with an interactive plan selection page where users choose from three plans before proceeding to payment.

## Context

This page appears as Step 2 of 2 in the onboarding flow, after the user completes the onboarding form. It is the entry point to checkout — the user selects a plan and clicks a CTA which submits a form POST to `SubscriptionsController#create`, passing `plan_tier` as a param.

**Critical rule:** `User#plan_tier` is set only after webhook payment confirmation, not on plan selection. The plan selection page simply passes the chosen tier to the checkout PORO as a param.

---

## Architecture

**Layout:** 3-column card grid (desktop), responsive stack (mobile). Each card has its own CTA button that submits the plan selection form with a hidden `plan_tier` field.

**Routing:** Existing route `new_subscription_path` (`GET /subscriptions/new`) and `subscriptions_path` (`POST /subscriptions`) are unchanged.

**Controller:** `SubscriptionsController#create` reads `params[:plan_tier]` instead of `current_user.plan_tier`. The checkout PORO receives the selected tier.

**View:** Replace `app/views/subscriptions/new.html.erb` entirely. No new controller or route needed.

---

## Components

### Page structure

- **Nav bar** — fixed, 56px, `border-bottom: 2px solid #2F2F2F`, "RADO FITNESS" logo in saffron (`#F5C228`), black background.
- **Step indicator** — small uppercase label "PASO 2 DE 2" in saffron, above the H1.
- **H1** — "ELEGÍ TU PLAN", uppercase, Switzer 900, `#F5F5F5`.
- **Subtitle** — "Suscripción mensual. Cancelá cuando quieras." in `#888`.
- **Plan grid** — `display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px`. On mobile, stacks to a single column.
- **Footer note** — Terms acceptance + cancel anytime notice in muted gray.

### Plan card (× 3)

Each card is a `<form method="post" action="/subscriptions">` wrapping:

- `2px solid #2F2F2F` border (featured card: `#F5C228`)
- Hover: `translate(-3px, -3px)` + `6px 6px 0 0 #2F2F2F` shadow (featured: saffron shadow)
- **Plan tier label** — 11px, 700, 0.18em tracking, uppercase, gray (featured: saffron)
- **Price block** — large amount (52px, 900) with `$` superscript, "USD / mes" period text
- **Divider** — 32px × 2px line, `#2F2F2F` (featured: saffron at 40% opacity)
- **Feature list** — placeholder copy, em-dash bullets; list grows to fill available space
- **CTA button** — submit button, 12px 900 uppercase

  - Basic / High Ticket: outlined (`border: 2px solid #2F2F2F`, transparent background)
  - Medium (featured): filled saffron (`background: #F5C228; color: #040307`)
  - Hover: `translate(-2px, -2px)` + `4px 4px 0 0` shadow

- **Hidden inputs:** `authenticity_token` + `plan_tier` value (`basic` / `medium` / `high_ticket`)
- **"Más popular" badge** on Medium card: absolute-positioned, saffron pill above top border

### Plans

| Tier | `plan_tier` value | Price | Featured |
|------|-------------------|-------|----------|
| Basic | `basic` | $10 USD/mes | No |
| Medium | `medium` | $50 USD/mes | Yes ("Más popular") |
| High Ticket | `high_ticket` | $100 USD/mes | No |

Feature list copy: placeholder text (3–4 bullets per card). Will be filled in later.

---

## Controller change

In `SubscriptionsController#create`, update `checkout` private method:

```ruby
def checkout
  plan = params[:plan_tier] || current_user.plan_tier
  if current_user.onboarding_profile&.argentina?
    Subscriptions::MercadoPagoCheckout.new(current_user, plan)
  else
    Subscriptions::StripeCheckout.new(current_user, plan)
  end
end
```

The fallback to `current_user.plan_tier` ensures backwards compatibility if called without a param.

---

## Visual reference

High-fidelity mockup: `.superpowers/brainstorm/47682-1773861681/plan-mockup.html`

Brand tokens:
- Background: `#040307`
- Saffron: `#F5C228`
- Graphite: `#2F2F2F`
- Whiteish: `#F5F5F5`
- Font: Switzer (900/700/500)
- Borders: 2px solid, no border-radius
- Shadows: `6px 6px 0 0` on cards, `4px 4px 0 0` on buttons

---

## Out of scope

- Feature copy (placeholders only, to be filled later)
- Mobile-specific design beyond responsive stacking
- Annual/monthly billing toggle
- Plan comparison table
- Any admin-side changes
