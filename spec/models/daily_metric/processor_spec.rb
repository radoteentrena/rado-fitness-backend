require "rails_helper"

RSpec.describe DailyMetric::Processor do
  describe "broadcast_compliance_scores" do
    let(:user) { create(:user) }
    let(:metric) { create(:daily_metric, user: user) }
    let(:processor) { described_class.new(metric) }

    before { metric }  # force factory creation before stub so after_save fires outside stub scope

    it "broadcasts to user_compliance stream after save" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_update_to)
      processor.run_after_save
      expect(Turbo::StreamsChannel).to have_received(:broadcast_update_to).with(
        "user_compliance_#{user.id}",
        hash_including(target: "user_compliance_scores_#{user.id}")
      )
    end
  end

  describe "Sentry: AI parse error" do
    let(:user) { create(:user) }
    let(:metric) { create(:daily_metric, user: user) }
    let(:processor) { described_class.new(metric) }

    before do
      metric.raw_message_content = "ate chicken"
      allow(GeminiService).to receive(:new).and_raise(StandardError, "AI unavailable")
      allow(Sentry).to receive(:capture_exception)
    end

    it "calls Sentry.capture_exception when AI parse raises" do
      processor.run
      expect(Sentry).to have_received(:capture_exception)
    end

    it "does not re-raise — metric still saves" do
      expect { processor.run }.not_to raise_error
    end
  end
end
