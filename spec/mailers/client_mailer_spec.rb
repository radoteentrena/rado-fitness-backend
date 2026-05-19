require "rails_helper"

RSpec.describe ClientMailer, type: :mailer do
  describe "#welcome" do
    before do
      allow_any_instance_of(ClientMailer).to receive(:app_host).and_return("example.com")
    end

    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:mail) { described_class.welcome(user) }

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "sends from the Rado address" do
      expect(mail.from).to eq(["info@radoteentrena.com"])
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

  describe "#call_booked" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:appointment_time) { "lunes 23 de junio a las 18:00" }
    let(:calendar_url) { "https://calendar.google.com/event/abc123" }
    let(:mail) { described_class.call_booked(user, appointment_time, calendar_url) }

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Tu llamada está confirmada")
    end

    it "includes the user first name" do
      expect(mail.body.encoded).to include("Carlos")
    end

    it "includes the appointment time" do
      expect(mail.body.encoded).to include("lunes 23 de junio a las 18:00")
    end

    it "includes the calendar URL" do
      expect(mail.body.encoded).to include("https://calendar.google.com/event/abc123")
    end
  end
end
