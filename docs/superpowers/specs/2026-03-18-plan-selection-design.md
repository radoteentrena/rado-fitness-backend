# Plan Selection Page — Design Spec

## Goal

Replace the current `subscriptions/new` view (which shows the user's pre-assigned plan) with an interactive plan selection page where users choose from three plans before proceeding to payment.

## Context

This page appears as Step 2 of 2 in the onboarding flow, after the user completes the onboarding form. It is the entry point to checkout — the user selects a plan and clicks a CTA which submits a form POST to `SubscriptionsController#create`, passing `plan_tier` as a param.

**Critical rule:** `User#plan_tier` is set only after webhook payment confirmation, not on plan selection. The plan selection page simply passes the chosen tier to the checkout PORO as a param.

**Dependency:** This spec builds on PR #25 (payment system). The following must exist before implementing:
- `SubscriptionsController` with `before_action :authenticate_user!`, `#new`, `#create`, and `#processing` actions
- Named routes: `new_subscription_path`, `subscriptions_path`, `subscriptions_processing_path`
- `app/views/subscriptions/new.html.erb` (to be replaced by this spec)
- `OnboardingProfile#argentina?` — returns true if `country == "AR"`
- `Subscriptions::StripeCheckout` and `Subscriptions::MercadoPagoCheckout` — both respond to `#call` returning `{ success:, redirect_url: }` or `{ success:, error: }`

---

## Architecture

**Layout:** 3-column card grid (desktop), responsive stack (mobile). Each plan card wraps a `form_with` that POST to `subscriptions_path` with a hidden `plan_tier` field. Clicking "Elegir [Plan]" submits that card's form.

**Routing:** Existing routes `new_subscription_path` and `subscriptions_path` are unchanged.

**Files to change:**
- Modify: `app/controllers/subscriptions_controller.rb` — update `checkout` private method, add param validation to `#create`
- Replace: `app/views/subscriptions/new.html.erb` — full rewrite

---

## Controller changes

### `#create` action (full body)

```ruby
def create
  plan = validated_plan_tier
  if plan.nil?
    redirect_to new_subscription_path, alert: "Plan inválido. Por favor elegí una opción."
    return
  end
  result = checkout(plan).call
  if result[:success]
    redirect_to result[:redirect_url], allow_other_host: true
  else
    redirect_to new_subscription_path, alert: "Hubo un error al procesar el pago. Intentá de nuevo."
  end
end
```

### Private methods

```ruby
VALID_PLAN_TIERS = %w[basic medium high_ticket].freeze

def validated_plan_tier
  tier = params[:plan_tier]
  VALID_PLAN_TIERS.include?(tier) ? tier : nil
end

def checkout(plan)
  if current_user.onboarding_profile&.argentina?
    Subscriptions::MercadoPagoCheckout.new(current_user, plan)
  else
    Subscriptions::StripeCheckout.new(current_user, plan)
  end
end
```

`authenticate_user!` is already set as a `before_action` for all actions (from PR #25). No change needed.

---

## View: `app/views/subscriptions/new.html.erb`

Use Rails `form_with` helpers (not raw HTML) — the authenticity token is injected automatically.

### Structure

```erb
<%# Nav (layout already provides the main nav; this page uses the existing application layout) %>

<div class="page">
  <header class="page-header">
    <div class="step-indicator">Paso 2 de 2</div>
    <h1>Elegí tu plan</h1>
    <p>Suscripción mensual. Cancelá cuando quieras.</p>
  </header>

  <div class="plans">
    <%# One form_with per plan card — see Plan cards section %>
  </div>

  <p class="footnote">
    Al continuar aceptás los <a href="#">términos y condiciones</a>.
    Podés cancelar en cualquier momento.
  </p>
</div>
```

The existing application layout provides the nav bar and Switzer font. Do not re-render a nav inside this view.

### Plan cards

Three `form_with(url: subscriptions_path, method: :post)` blocks, one per plan:

| Tier | `plan_tier` hidden value | Price | CTA text | Featured |
|------|--------------------------|-------|----------|----------|
| Basic | `basic` | $10 | Elegir Basic | No |
| Medium | `medium` | $50 | Elegir Medium | Yes |
| High Ticket | `high_ticket` | $100 | Elegir High Ticket | No |

Each form renders:
- Hidden field: `plan_tier` with the tier value
- Plan tier label (uppercase, tracked)
- Price block: large amount + "USD / mes" period
- Horizontal divider
- Feature list (placeholder copy, 3–4 items)
- Submit button styled as CTA

Pricing is shown in USD to all users. Argentine users pay in ARS via MercadoPago, but prices are configured in the MercadoPago dashboard — the selection page always shows USD amounts.

### CSS approach

Inline `<style>` block in the view (matching existing pattern in this app), using the brand tokens below. No Tailwind — this view uses plain CSS as per the existing `subscriptions/new.html.erb` pattern.

---

## Visual specification

### Plan card

- Border: `2px solid #2F2F2F` (featured: `#F5C228`)
- No border-radius
- Hover: `transform: translate(-3px, -3px)` + `box-shadow: 6px 6px 0 0 #2F2F2F` (featured: saffron shadow)
- Cursor: pointer
- Padding: `32px 28px`
- Position: relative

**"Más popular" badge** (Medium only):
- Absolute, `top: -13px`, horizontally centered
- Background `#F5C228`, color `#040307`
- Font: 10px, 900, 0.14em tracking, uppercase

**Plan tier label:**
- 11px, 700, 0.18em tracking, uppercase
- Color: `#888` (featured: `#F5C228`)

**Price block:**
- Amount: 52px, 900, color `#F5F5F5`, line-height 1
- `$` superscript: 22px, 700, color `#888`, `vertical-align: top`
- Period: "USD / mes", 13px, `#555`, 500

**Divider:**
- 32px wide, 2px height, `#2F2F2F` (featured: `#F5C228` at 40% opacity)
- Margin: 20px top/bottom

**Feature list:**
- `list-style: none`, flex column, gap 10px, flex: 1
- Each item: 13px, `#888`, padding-left 16px, em-dash bullet (`—`) at left: 0, color `#3a3a3a` (featured: `#F5C228` at 50% opacity)

**CTA button (submit):**
- Full width, padding `13px 0`, 12px, 900, 0.14em tracking, uppercase
- Border: `2px solid`
- No border-radius
- Basic/High Ticket: `border-color: #2F2F2F`, `background: transparent`, `color: #F5F5F5`
- Medium: `background: #F5C228`, `border-color: #F5C228`, `color: #040307`
- Hover (Basic/High Ticket): `border-color: #F5F5F5`, `box-shadow: 4px 4px 0 0 #2F2F2F`, `transform: translate(-2px, -2px)`
- Hover (Medium): `box-shadow: 4px 4px 0 0 #fff`
- Transition: `0.1s` on shadow, transform, border-color, background, color

### Page layout

- Background: `#040307`
- Max width: 960px, centered
- Padding: `64px 0 48px` (below nav)

**Step indicator:** 11px, 700, 0.15em tracking, uppercase, `#F5C228`, margin-bottom 16px

**H1:** 42px, 900, -0.01em letter-spacing, uppercase, `#F5F5F5`, line-height 1.05

**Subtitle:** 15px, `#888`, 0.02em tracking

**Plan grid:** `display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; align-items: stretch`

**Footnote:** 12px, `#444`, centered, margin-top 32px; link color `#666`, underline

### Mobile (≤ 640px)

Grid collapses to `grid-template-columns: 1fr`. Cards stack vertically.

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
- Annual/monthly billing toggle
- Plan comparison table
- Any admin-side changes
- ARS price display for Argentine users (MercadoPago dashboard handles this)
