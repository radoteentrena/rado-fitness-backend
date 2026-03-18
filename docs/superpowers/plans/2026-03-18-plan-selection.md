# Plan Selection Page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static plan display in `subscriptions/new` with an interactive 3-plan selection grid (Basic $10, Medium $50, High Ticket $100) that lets users choose a plan before proceeding to checkout.

**Architecture:** Three targeted changes — (1) `SubscriptionsController` gains an allowlist param validator and routes the selected tier to the checkout PORO; (2) `OnboardingController` redirects to `new_subscription_path` after form submission instead of the static success page; (3) `app/views/subscriptions/new.html.erb` becomes a 3-column card grid. The view uses **Tailwind v4 utility classes** matching the established app pattern — all existing views in this app use Tailwind, not plain CSS. (The spec incorrectly stated "no Tailwind" — that referred to the standalone mockup HTML file, not the app's actual convention.)

**Tech Stack:** Rails 8, RSpec request specs, Tailwind CSS v4 (custom tokens: `bg-saffron`, `text-saffron`, `border-saffron`, `bg-graphite`, `border-graphite`, `text-whiteish`, `bg-blackish`, `text-blackish`, `font-display`), `form_with` Rails helpers.

**Prerequisite:** PR #25 (payment system) must be merged before implementing this plan. That PR provides:
- `SubscriptionsController` skeleton with `before_action :authenticate_user!`
- Named subscription routes (`new_subscription_path`, `subscriptions_path`, `subscriptions_processing_path`)
- `OnboardingProfile#argentina?`
- Checkout POROs (`Subscriptions::StripeCheckout`, `Subscriptions::MercadoPagoCheckout`)
- Devise test helpers in `spec/rails_helper.rb`: `Devise::Test::IntegrationHelpers` + `Warden::Test::Helpers`
- `spec/factories/users.rb` with `:user` factory

**If PR #25 is not yet merged,** check `spec/rails_helper.rb` for the Devise includes and `spec/factories/users.rb` for the factory before running specs. If either is missing, see the setup notes at the end of this document.

---

## File Map

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `app/controllers/subscriptions_controller.rb` | Add `layout`, param allowlist, update `#create` and `checkout` |
| Modify | `app/controllers/onboarding_controller.rb` | Change post-form redirect to `new_subscription_path` |
| Replace | `app/views/subscriptions/new.html.erb` | 3-plan card grid (Tailwind) |
| Create or Modify | `spec/requests/subscriptions_spec.rb` | Add param validation and plan routing tests (create file if not yet merged from PR #25) |
| Create | `spec/requests/onboarding_spec.rb` | Test post-form redirect target |

---

## Task 1: Controller — param validation and layout

**Files:**
- Modify: `app/controllers/subscriptions_controller.rb`
- Modify: `spec/requests/subscriptions_spec.rb`

The existing `SubscriptionsController` (from PR #25) reads `current_user.plan_tier` in `checkout`. We need to:
1. Add `layout "homepage"` — the homepage layout provides a bare `<main>` without the application layout's `container mx-auto flex` wrapping, which would constrain the plan grid
2. Add a `VALID_PLAN_TIERS` allowlist constant
3. Update `#create` to validate `params[:plan_tier]` before calling checkout
4. Update `checkout` to accept the validated plan as an argument

---

- [ ] **Step 1.1: Write failing tests for param validation**

Open `spec/requests/subscriptions_spec.rb`. If the file does not exist yet (PR #25 not merged), create it with this wrapper first:

```ruby
require "rails_helper"

RSpec.describe "Subscriptions", type: :request do
end
```

Then add these examples inside the `RSpec.describe` block (alongside any existing describe blocks):

```ruby
describe "POST /subscriptions with plan_tier param" do
  let(:user) { create(:user) }
  let(:checkout_double) do
    instance_double(
      "Subscriptions::StripeCheckout",
      call: { success: true, redirect_url: "https://checkout.stripe.com/pay/test" }
    )
  end

  before { sign_in user }

  context "with a valid plan_tier" do
    before do
      allow(Subscriptions::StripeCheckout).to receive(:new).and_return(checkout_double)
    end

    it "passes the selected plan to the checkout service" do
      post subscriptions_path, params: { plan_tier: "medium" }
      expect(Subscriptions::StripeCheckout).to have_received(:new).with(user, "medium")
    end

    it "redirects to the checkout URL on success" do
      post subscriptions_path, params: { plan_tier: "basic" }
      expect(response).to redirect_to("https://checkout.stripe.com/pay/test")
    end
  end

  context "with an invalid plan_tier" do
    it "redirects back with a Spanish alert" do
      post subscriptions_path, params: { plan_tier: "hacker" }
      expect(response).to redirect_to(new_subscription_path)
      expect(flash[:alert]).to match(/Plan inválido/)
    end
  end

  context "with a missing plan_tier" do
    it "redirects back with a Spanish alert" do
      post subscriptions_path
      expect(response).to redirect_to(new_subscription_path)
      expect(flash[:alert]).to match(/Plan inválido/)
    end
  end
end
```

- [ ] **Step 1.2: Run tests — confirm they fail**

```bash
bundle exec rspec spec/requests/subscriptions_spec.rb --format documentation
```

Expected: new examples fail — either wrong number of args to `checkout` or `StripeCheckout.new` not called with the right tier.

- [ ] **Step 1.3: Update the controller**

Replace the entire contents of `app/controllers/subscriptions_controller.rb` with:

```ruby
class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  layout "homepage"

  VALID_PLAN_TIERS = %w[basic medium high_ticket].freeze

  def new; end

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

  def processing; end

  private

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
end
```

- [ ] **Step 1.4: Run tests — confirm they pass**

```bash
bundle exec rspec spec/requests/subscriptions_spec.rb --format documentation
```

Expected: all examples pass, including the new param validation ones.

- [ ] **Step 1.5: Run full test suite**

```bash
bundle exec rspec --format progress
```

Expected: 0 failures.

- [ ] **Step 1.6: Commit**

```bash
git add app/controllers/subscriptions_controller.rb spec/requests/subscriptions_spec.rb
git commit -m "feat: validate plan_tier param in SubscriptionsController"
```

---

## Task 2: Wire onboarding redirect to plan selection

**Files:**
- Modify: `app/controllers/onboarding_controller.rb`
- Create: `spec/requests/onboarding_spec.rb`

`OnboardingController#create` currently redirects to `onboarding_success_path` after saving. The flow should go to `new_subscription_path` so the plan selection page is "Step 2 of 2" immediately after the form.

**Test strategy:** The onboarding form is a 15-step form that creates a User without a password field (the controller's `onboarding_params` does not permit `:password`). Rather than trying to submit a full valid form through the controller, we mock `User#save` to return `true` so the test is purely about the redirect target — not about Devise password validations.

---

- [ ] **Step 2.1: Write a failing test**

Create `spec/requests/onboarding_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  describe "POST /onboarding" do
    context "when user saves successfully" do
      before do
        # Mock save so we don't need a full valid form submission.
        # OnboardingController#create does not permit :password in params,
        # so Devise validation would reject the save without this mock.
        allow_any_instance_of(User).to receive(:save).and_return(true)
        allow_any_instance_of(User).to receive(:onboarding_profile_attributes=)
      end

      it "redirects to the plan selection page" do
        # Must include onboarding_profile_attributes key — the controller
        # accesses params[:user][:onboarding_profile_attributes][:goals]
        # before calling save, so omitting it raises NoMethodError.
        post onboarding_path, params: {
          user: {
            first_name: "Ana",
            last_name: "García",
            email: "ana@example.com",
            phone: "+541112345678",
            onboarding_profile_attributes: { goals: [] }
          }
        }
        expect(response).to redirect_to(new_subscription_path)
      end
    end
  end
end
```

- [ ] **Step 2.2: Run the test — confirm it fails**

```bash
bundle exec rspec spec/requests/onboarding_spec.rb --format documentation
```

Expected: FAIL — response redirects to `onboarding_success_path`, not `new_subscription_path`.

- [ ] **Step 2.3: Update the redirect**

In `app/controllers/onboarding_controller.rb`, in the `create` action, find:

```ruby
redirect_to onboarding_success_path
```

Replace with:

```ruby
redirect_to new_subscription_path
```

- [ ] **Step 2.4: Run tests — confirm they pass**

```bash
bundle exec rspec spec/requests/onboarding_spec.rb --format documentation
```

Expected: PASS.

- [ ] **Step 2.5: Run full test suite**

```bash
bundle exec rspec --format progress
```

Expected: 0 failures.

- [ ] **Step 2.6: Commit**

```bash
git add app/controllers/onboarding_controller.rb spec/requests/onboarding_spec.rb
git commit -m "feat: redirect to plan selection after onboarding form"
```

---

## Task 3: Plan selection view

**Files:**
- Replace: `app/views/subscriptions/new.html.erb`

Build the 3-plan card grid. The view uses the `homepage` layout (set on the controller in Task 1). That layout provides:

```html
<body class="bg-black text-white antialiased">
  <main><%= yield %></main>
</body>
```

No container constraints — the view owns its own padding and max-width.

**Tailwind tokens in use:**
- `bg-blackish` — `#040307` (deep black background)
- `text-saffron` / `bg-saffron` / `border-saffron` — `#F5C228`
- `text-whiteish` — `#F5F5F5`
- `border-graphite` — `#2F2F2F`
- `text-blackish` — `#040307`
- `font-display` — Switzer font (mapped via `--font-display` in `application.css`)

**`form_with class: "contents"` pattern:** Each card is wrapped in its own `form_with`. The `class: "contents"` on the form element makes it invisible to the CSS grid — the inner card `<div>` becomes a direct grid item. This is the cleanest approach for one form per card without breaking the 3-column layout.

**No additional test needed** — the `GET /subscriptions/new` → 200 spec from PR #25 covers this. Re-running the full suite after replacing the view confirms no regressions.

---

- [ ] **Step 3.1: Replace the view**

Replace `app/views/subscriptions/new.html.erb` entirely with:

```erb
<div class="bg-blackish min-h-screen font-display py-20 px-6">
  <div class="max-w-5xl mx-auto">

    <%# Page header %>
    <header class="text-center mb-14">
      <span class="block text-[11px] font-bold tracking-[0.15em] uppercase text-saffron mb-4">
        Paso 2 de 2
      </span>
      <h1 class="text-[42px] font-black uppercase text-whiteish leading-[1.05] tracking-tight mb-3">
        Elegí tu plan
      </h1>
      <p class="text-[15px] text-[#888] tracking-wide">
        Suscripción mensual. Cancelá cuando quieras.
      </p>
    </header>

    <%# Flash alert %>
    <% if flash[:alert] %>
      <div class="max-w-2xl mx-auto mb-8 border-2 border-red-500 p-4 text-red-400 text-sm text-center">
        <%= flash[:alert] %>
      </div>
    <% end %>

    <%# Plan grid — one form per card %>
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-6 items-stretch">

      <%# Basic %>
      <%= form_with url: subscriptions_path, method: :post, class: "contents" do |f| %>
        <%= f.hidden_field :plan_tier, value: "basic" %>
        <div class="border-2 border-graphite relative flex flex-col p-8 cursor-pointer
                    hover:-translate-x-1 hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_#2F2F2F]
                    transition-all duration-100">
          <p class="text-[11px] font-bold tracking-[0.18em] uppercase text-[#888] mb-4">Basic</p>
          <div class="mb-1">
            <span class="text-[52px] font-black text-whiteish leading-none">
              <span class="text-[22px] font-bold text-[#888] align-top mt-2.5 inline-block">$</span>10
            </span>
            <p class="text-[13px] text-[#555] font-medium mt-1">USD / mes</p>
          </div>
          <div class="w-8 h-0.5 bg-graphite my-5"></div>
          <ul class="flex-1 flex flex-col gap-2.5 mb-7 list-none p-0">
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio uno
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio dos
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio tres
            </li>
          </ul>
          <%= f.submit "Elegir Basic",
              class: "w-full py-3.5 text-xs font-black tracking-[0.14em] uppercase
                      border-2 border-graphite text-whiteish bg-transparent cursor-pointer
                      hover:border-whiteish hover:shadow-[4px_4px_0px_0px_#2F2F2F]
                      hover:-translate-x-0.5 hover:-translate-y-0.5
                      transition-all duration-100" %>
        </div>
      <% end %>

      <%# Medium — featured %>
      <%= form_with url: subscriptions_path, method: :post, class: "contents" do |f| %>
        <%= f.hidden_field :plan_tier, value: "medium" %>
        <div class="border-2 border-saffron relative flex flex-col p-8 cursor-pointer
                    hover:-translate-x-1 hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_#F5C228]
                    transition-all duration-100">
          <span class="absolute -top-3 left-1/2 -translate-x-1/2
                       bg-saffron text-blackish text-[10px] font-black tracking-[0.14em] uppercase
                       px-3 py-0.5 whitespace-nowrap">
            Más popular
          </span>
          <p class="text-[11px] font-bold tracking-[0.18em] uppercase text-saffron mb-4">Medium</p>
          <div class="mb-1">
            <span class="text-[52px] font-black text-whiteish leading-none">
              <span class="text-[22px] font-bold text-[#888] align-top mt-2.5 inline-block">$</span>50
            </span>
            <p class="text-[13px] text-[#555] font-medium mt-1">USD / mes</p>
          </div>
          <div class="w-8 h-0.5 bg-saffron opacity-40 my-5"></div>
          <ul class="flex-1 flex flex-col gap-2.5 mb-7 list-none p-0">
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-saffron before:opacity-50 before:font-bold">
              Todo lo de Basic
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-saffron before:opacity-50 before:font-bold">
              Placeholder beneficio cuatro
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-saffron before:opacity-50 before:font-bold">
              Placeholder beneficio cinco
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-saffron before:opacity-50 before:font-bold">
              Placeholder beneficio seis
            </li>
          </ul>
          <%= f.submit "Elegir Medium",
              class: "w-full py-3.5 text-xs font-black tracking-[0.14em] uppercase
                      bg-saffron border-2 border-saffron text-blackish cursor-pointer
                      hover:shadow-[4px_4px_0px_0px_#fff]
                      hover:-translate-x-0.5 hover:-translate-y-0.5
                      transition-all duration-100" %>
        </div>
      <% end %>

      <%# High Ticket %>
      <%= form_with url: subscriptions_path, method: :post, class: "contents" do |f| %>
        <%= f.hidden_field :plan_tier, value: "high_ticket" %>
        <div class="border-2 border-graphite relative flex flex-col p-8 cursor-pointer
                    hover:-translate-x-1 hover:-translate-y-1 hover:shadow-[6px_6px_0px_0px_#2F2F2F]
                    transition-all duration-100">
          <p class="text-[11px] font-bold tracking-[0.18em] uppercase text-[#888] mb-4">High Ticket</p>
          <div class="mb-1">
            <span class="text-[52px] font-black text-whiteish leading-none">
              <span class="text-[22px] font-bold text-[#888] align-top mt-2.5 inline-block">$</span>100
            </span>
            <p class="text-[13px] text-[#555] font-medium mt-1">USD / mes</p>
          </div>
          <div class="w-8 h-0.5 bg-graphite my-5"></div>
          <ul class="flex-1 flex flex-col gap-2.5 mb-7 list-none p-0">
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Todo lo de Medium
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio siete
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio ocho
            </li>
            <li class="text-[13px] text-[#888] pl-4 relative leading-snug
                       before:absolute before:left-0 before:content-['—'] before:text-[#3a3a3a] before:font-bold">
              Placeholder beneficio nueve
            </li>
          </ul>
          <%= f.submit "Elegir High Ticket",
              class: "w-full py-3.5 text-xs font-black tracking-[0.14em] uppercase
                      border-2 border-graphite text-whiteish bg-transparent cursor-pointer
                      hover:border-whiteish hover:shadow-[4px_4px_0px_0px_#2F2F2F]
                      hover:-translate-x-0.5 hover:-translate-y-0.5
                      transition-all duration-100" %>
        </div>
      <% end %>

    </div>

    <%# Footer note %>
    <p class="text-center mt-8 text-xs text-[#444] tracking-wide">
      Al continuar aceptás los <a href="#" class="text-[#666] underline">términos y condiciones</a>.
      Podés cancelar en cualquier momento.
    </p>

  </div>
</div>
```

- [ ] **Step 3.2: Run subscription specs — confirm no regressions**

```bash
bundle exec rspec spec/requests/subscriptions_spec.rb --format documentation
```

Expected: all pass, including the `GET /subscriptions/new` → 200 example from PR #25.

- [ ] **Step 3.3: Run full test suite**

```bash
bundle exec rspec --format progress
```

Expected: 0 failures.

- [ ] **Step 3.4: Commit**

```bash
git add app/views/subscriptions/new.html.erb
git commit -m "feat: plan selection page with 3-plan card grid"
```

---

## Setup notes (if PR #25 is not yet merged)

**If `sign_in` is undefined in request specs**, add to `spec/rails_helper.rb`:

```ruby
# Outside the RSpec.configure block:
include Warden::Test::Helpers

# Inside the RSpec.configure do |config| block:
config.include Devise::Test::IntegrationHelpers, type: :request
```

Note: `Warden::Test::Helpers` must be included at the top level (outside `RSpec.configure`) — placing it inside the configure block with `config.include` does not work correctly with the Warden test middleware.

**If `create(:user)` raises "Factory not registered"**, create `spec/factories/users.rb`:

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { "Test" }
    last_name  { "User" }
    phone      { "+541112345678" }
    status     { :lead }
  end
end
```

---

## Done

All three tasks complete. The plan selection feature is fully wired:

- `POST /onboarding` → `new_subscription_path` (Step 2 of 2)
- `GET /subscriptions/new` → 3-plan card grid in brand style
- `POST /subscriptions` with `plan_tier=basic|medium|high_ticket` → correct checkout PORO → payment redirect
- Invalid or missing `plan_tier` → redirect back with Spanish alert
