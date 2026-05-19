require "rails_helper"

RSpec.describe SubscriptionMailer, type: :mailer do
  describe "#confirmed" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:subscription) { create(:subscription, user: user, plan_tier: :high_ticket, amount_cents: 10_000) }
    let(:mail) { described_class.confirmed(user, subscription) }

    before do
      allow_any_instance_of(SubscriptionMailer).to receive(:app_host).and_return("example.com")
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

    it "sends from the Rado address" do
      expect(mail.from).to eq(["info@radoteentrena.com"])
    end
  end
end
