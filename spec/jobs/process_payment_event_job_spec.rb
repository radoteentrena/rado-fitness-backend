require "rails_helper"

RSpec.describe ProcessPaymentEventJob, type: :job do
  let(:user) { create(:user, status: :lead, plan_tier: :basic) }

  describe "mercadopago: preapproval authorized" do
    let(:mp_sub_id) { "mp_sub_123" }
    let(:mp_plan_id) { "mp_plan_basic" }
    let(:payload) do
      {
        "type" => "preapproval",
        "data" => { "id" => mp_sub_id }
      }
    end

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).with(mp_sub_id).and_return({
        "response" => {
          "id" => mp_sub_id,
          "status" => "authorized",
          "external_reference" => user.id.to_s,
          "preapproval_plan_id" => mp_plan_id,
          "payer_id" => "mp_payer_456",
          "next_payment_date" => 30.days.from_now.iso8601
        }
      })
    end

    it "creates Subscription and activates user" do
      described_class.perform_now(
        processor: "mercadopago",
        event_type: "preapproval",
        payload: payload
      )

      sub = user.reload.active_subscription
      expect(sub).to be_active
      expect(sub.external_id).to eq(mp_sub_id)
      expect(user.reload).to be_active
    end

    it "enqueues a confirmed email for a new subscription" do
      expect {
        described_class.perform_now(
          processor: "mercadopago",
          event_type: "preapproval",
          payload: payload
        )
      }.to have_enqueued_mail(SubscriptionMailer, :confirmed)
    end

    it "auto-assigns a program for a basic_tier user" do
      matcher = instance_double(ProgramMatcherService, call: nil)
      expect(ProgramMatcherService).to receive(:new).with(user).and_return(matcher)

      described_class.perform_now(
        processor: "mercadopago",
        event_type: "preapproval",
        payload: payload
      )
    end

    it "auto-assigns the closest dietary plan for a basic_tier user" do
      plan = instance_double(DietaryPlan, id: 42)
      allow(HarrisBenedict).to receive(:tdee).with(user).and_return(2200)
      expect(DietaryPlan).to receive(:closest_to_calories).with(2200).and_return(plan)
      expect(plan).to receive(:assign_to_user).with(user)

      described_class.perform_now(
        processor: "mercadopago",
        event_type: "preapproval",
        payload: payload
      )
    end

    context "when the user is not basic_tier" do
      let(:user) { create(:user, status: :lead, plan_tier: :medium) }

      it "does not auto-assign a program or dietary plan (coach assigns manually)" do
        expect(ProgramMatcherService).not_to receive(:new)
        expect(HarrisBenedict).not_to receive(:tdee)

        described_class.perform_now(
          processor: "mercadopago",
          event_type: "preapproval",
          payload: payload
        )
      end
    end

    context "when a subscription already exists for this user" do
      before { create(:subscription, user: user, billing_type: :recurring, status: :active, external_id: mp_sub_id) }

      it "enqueues a renewed email" do
        expect {
          described_class.perform_now(
            processor: "mercadopago",
            event_type: "preapproval",
            payload: payload
          )
        }.to have_enqueued_mail(SubscriptionMailer, :renewed)
      end
    end
  end

  describe "mercadopago: recurring subscription activation (preapproval_plan)" do
    let(:user) { create(:user, status: :lead, plan_tier: nil) }
    let(:mp_sub_id) { "mp_pa_999" }
    let(:payload) { { "type" => "preapproval", "data" => { "id" => mp_sub_id } } }

    # The pending subscription created at checkout carries the chosen plan_tier.
    let!(:pending) do
      create(:subscription, user: user, billing_type: :recurring, status: :pending,
             plan_tier: :basic, external_id: nil, external_customer_id: nil)
    end

    before do
      sdk = instance_double(Mercadopago::SDK)
      preapproval = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk)
      allow(sdk).to receive(:preapproval).and_return(preapproval)
      allow(preapproval).to receive(:get).with(mp_sub_id).and_return({
        "response" => {
          "id" => mp_sub_id,
          "status" => "authorized",
          "external_reference" => nil,      # preapproval_plan checkouts may omit this
          "payer_email" => user.email,      # so we resolve by payer email instead
          "preapproval_plan_id" => "mp_plan_basic",
          "payer_id" => "payer_1",
          "next_payment_date" => 30.days.from_now.iso8601
        }
      })
    end

    it "resolves the user by payer_email, sets plan_tier, activates, and promotes the pending sub" do
      described_class.perform_now(processor: "mercadopago", event_type: "preapproval", payload: payload)

      user.reload
      expect(user).to be_active
      expect(user.plan_tier).to eq("basic")
      expect(pending.reload).to be_active
      expect(pending.external_id).to eq(mp_sub_id)
    end
  end

  describe "mercadopago: payment rejected (recurring charge failure)" do
    let!(:subscription) { create(:subscription, user: user, status: :active, external_id: "mp_sub_123") }
    let(:payload) { { "type" => "payment", "data" => { "id" => "mp_payment_456" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      payment_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:payment).and_return(payment_double)
      allow(payment_double).to receive(:get).with("mp_payment_456").and_return({
        "response" => {
          "id" => "mp_payment_456",
          "status" => "rejected",
          "metadata" => { "preapproval_id" => "mp_sub_123" }
        }
      })
    end

    it "marks subscription past_due and creates a CoachAlert" do
      expect {
        described_class.perform_now(
          processor: "mercadopago",
          event_type: "payment",
          payload: payload
        )
      }.to change(CoachAlert, :count).by(1)

      expect(subscription.reload).to be_past_due
      expect(CoachAlert.last.category).to eq("payment_failed")
    end
  end

  describe "mercadopago: preapproval cancelled" do
    let!(:subscription) do
      create(:subscription, user: user, status: :active, external_id: "mp_sub_123",
                            current_period_end: nil)
    end
    let(:payload) { { "type" => "preapproval", "data" => { "id" => "mp_sub_123" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).and_return({
        "response" => {
          "id" => "mp_sub_123",
          "status" => "cancelled",
          "external_reference" => user.id.to_s
        }
      })
    end

    it "cancels the subscription identified by external_id, not an arbitrary row" do
      other_sub = create(:subscription, user: user, status: :active, external_id: "mp_other_999")

      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )

      expect(subscription.reload).to be_canceled
      expect(other_sub.reload).to be_active
    end

    it "locks access immediately when current_period_end is nil" do
      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )
      expect(user.reload).to be_access_locked
    end

    it "does NOT lock access when current_period_end is still in the future" do
      subscription.update!(current_period_end: 10.days.from_now)

      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )

      expect(user.reload).not_to be_access_locked
    end

    it "churns user regardless of period end" do
      described_class.perform_now(
        processor:  "mercadopago",
        event_type: "preapproval",
        payload:    payload
      )
      expect(user.reload).to be_churned
    end
  end

  describe "mercadopago: checkout pro payment approved" do
    let!(:subscription) do
      create(:subscription, user: user, status: :pending, mp_preference_id: "pref_123")
    end
    let(:payload) { { "type" => "payment", "data" => { "id" => "mp_payment_789" } } }

    before do
      sdk_double     = instance_double(Mercadopago::SDK)
      payment_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:payment).and_return(payment_double)
      allow(payment_double).to receive(:get).with("mp_payment_789").and_return({
        "response" => {
          "id"            => "mp_payment_789",
          "status"        => "approved",
          "preference_id" => "pref_123",
          "date_approved" => Time.current.iso8601,
          "metadata"      => {}
        }
      })
    end

    it "enqueues a confirmed email" do
      expect {
        described_class.perform_now(
          processor:  "mercadopago",
          event_type: "payment",
          payload:    payload
        )
      }.to have_enqueued_mail(SubscriptionMailer, :confirmed)
    end
  end

  describe "Sentry: user not found" do
    let(:payload) { { "data" => { "id" => "mp_sub_999" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).with("mp_sub_999").and_return({
        "response" => {
          "id" => "mp_sub_999",
          "status" => "authorized",
          "external_reference" => "99999999",
          "payer_id" => "payer_x"
        }
      })
      allow(Sentry).to receive(:capture_message)
    end

    it "calls Sentry.capture_message when user is not found" do
      described_class.perform_now(processor: "mercadopago", event_type: "preapproval", payload: payload)
      expect(Sentry).to have_received(:capture_message).with(
        a_string_matching(/no user/i),
        level: :error
      )
    end
  end

  describe "Sentry: MP API error" do
    let(:payload) { { "data" => { "id" => "mp_sub_bad" } } }

    before do
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).and_raise(StandardError, "timeout")
      allow(Sentry).to receive(:capture_exception)
    end

    it "calls Sentry.capture_exception on MP API error" do
      described_class.perform_now(processor: "mercadopago", event_type: "preapproval", payload: payload)
      expect(Sentry).to have_received(:capture_exception)
    end
  end

  describe "payment toast broadcast" do
    let(:mp_sub_id) { "mp_sub_toast" }
    let(:payload) { { "data" => { "id" => mp_sub_id } } }

    def stub_preapproval(status)
      sdk_double = instance_double(Mercadopago::SDK)
      preapproval_double = double
      allow(Mercadopago::SDK).to receive(:new).and_return(sdk_double)
      allow(sdk_double).to receive(:preapproval).and_return(preapproval_double)
      allow(preapproval_double).to receive(:get).with(mp_sub_id).and_return({
        "response" => {
          "id" => mp_sub_id,
          "status" => status,
          "external_reference" => user.id.to_s,
          "payer_id" => "payer_x"
        }
      })
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to)
    end

    it "broadcasts authorized toast when preapproval is authorized" do
      stub_preapproval("authorized")
      described_class.perform_now(processor: "mercadopago", event_type: "preapproval", payload: payload)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        "admin_payment_events",
        hash_including(target: "admin_toast_container", locals: hash_including(toast_type: :authorized))
      )
    end

    it "broadcasts cancelled toast when preapproval is cancelled" do
      stub_preapproval("cancelled")
      create(:subscription, user: user, external_id: mp_sub_id, status: :active)
      described_class.perform_now(processor: "mercadopago", event_type: "preapproval", payload: payload)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        "admin_payment_events",
        hash_including(target: "admin_toast_container", locals: hash_including(toast_type: :cancelled))
      )
    end
  end
end
