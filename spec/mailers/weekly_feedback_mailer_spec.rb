require "rails_helper"

RSpec.describe WeeklyFeedbackMailer, type: :mailer do
  describe "#summary" do
    let(:user) { create(:user, first_name: "Carlos", email: "carlos@example.com") }
    let(:mail) do
      described_class.summary(
        user,
        feedback_text:       "Buena semana. Mantené la consistencia.",
        workouts_this_week:  4,
        diet_adherence:      85,
        current_weight:      82.5,
        week_number:         12
      )
    end

    before do
      allow_any_instance_of(ApplicationMailer).to receive(:app_host).and_return("example.com")
    end

    it "sends to the user email" do
      expect(mail.to).to eq(["carlos@example.com"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Tu resumen semanal — Semana 12")
    end

    it "includes the user first name" do
      expect(mail.body.encoded).to include("Carlos")
    end

    it "includes the feedback text" do
      expect(mail.body.encoded).to include("Buena semana. Mantené la consistencia.")
    end

    it "includes the workouts count" do
      expect(mail.body.encoded).to include("4")
    end

    it "includes the diet adherence" do
      expect(mail.body.encoded).to include("85")
    end

    it "includes the current weight" do
      expect(mail.body.encoded).to include("82.5")
    end

    it "includes the dashboard URL with the configured host" do
      expect(mail.body.encoded).to include("https://example.com")
    end

    it "sends from the Rado address" do
      expect(mail.from).to eq(["info@radoteentrena.com"])
    end

    it "enqueues with deliver_later" do
      expect { mail.deliver_later }
        .to have_enqueued_mail(WeeklyFeedbackMailer, :summary)
    end
  end
end
