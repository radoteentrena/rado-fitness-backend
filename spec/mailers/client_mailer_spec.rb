require "rails_helper"

RSpec.describe ClientMailer, type: :mailer do
  describe "#welcome" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:mail) { described_class.welcome(user) }

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Bienvenido, Carlos. Empezamos.")
    end

    it "includes the user first name in the body" do
      expect(mail.body.encoded).to include("Carlos")
    end

    it "includes a link to the subscriptions page" do
      expect(mail.body.encoded).to include("subscription")
    end

    it "includes the anti-spam nudge" do
      expect(mail.body.encoded).to include("bandeja principal")
    end
  end
end
