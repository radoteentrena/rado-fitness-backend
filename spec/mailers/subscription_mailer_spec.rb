require "rails_helper"

RSpec.describe SubscriptionMailer, type: :mailer do
  describe "#confirmed" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:subscription) { create(:subscription, user: user, plan_tier: :high_ticket, amount_cents: 10_000) }
    let(:mail) { described_class.confirmed(user, subscription) }

    before do
      allow_any_instance_of(ApplicationMailer).to receive(:app_host).and_return("example.com")
    end

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Acceso activado. Estás adentro.")
    end

    it "includes the user first name" do
      expect(mail.body.encoded).to include("Carlos")
    end

    it "includes the plan tier" do
      expect(mail.body.encoded).to include("High ticket")
    end

    it "includes the dashboard URL with the configured host" do
      expect(mail.body.encoded).to include("https://example.com")
    end

    it "sends from the Rado address" do
      expect(mail.from).to eq(["info@radoteentrena.com"])
    end

    it "enqueues with deliver_later" do
      expect { mail.deliver_later }
        .to have_enqueued_mail(SubscriptionMailer, :confirmed)
    end
  end

  describe "#renewed" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:subscription) do
      create(:subscription, user: user, plan_tier: :high_ticket,
             current_period_end: Time.zone.parse("2026-06-19 12:00:00"))
    end
    let(:mail) { described_class.renewed(user, subscription) }

    before do
      allow_any_instance_of(ApplicationMailer).to receive(:app_host).and_return("example.com")
    end

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Suscripción renovada. Seguimos.")
    end

    it "includes the user first name" do
      expect(mail.body.encoded).to include("Carlos")
    end

    it "includes the next renewal date" do
      expected = Time.zone.parse("2026-06-19 12:00:00").strftime("%d de %B de %Y")
      expect(mail.body.encoded).to include(expected)
    end

    it "includes the dashboard URL with the configured host" do
      expect(mail.body.encoded).to include("https://example.com")
    end

    it "sends from the Rado address" do
      expect(mail.from).to eq(["info@radoteentrena.com"])
    end

    it "enqueues with deliver_later" do
      expect { mail.deliver_later }
        .to have_enqueued_mail(SubscriptionMailer, :renewed)
    end

    context "when current_period_end is nil" do
      let(:subscription) { create(:subscription, user: user, plan_tier: :high_ticket, current_period_end: nil) }

      it "omits the renewal date block" do
        expect(mail.body.encoded).not_to include("Próxima renovación")
      end
    end
  end
end
