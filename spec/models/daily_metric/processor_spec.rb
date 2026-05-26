require "rails_helper"

RSpec.describe DailyMetric::Processor do
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
