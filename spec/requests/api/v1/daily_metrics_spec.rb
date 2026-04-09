require 'rails_helper'

RSpec.describe "POST /api/v1/daily_metrics", type: :request do
  let(:user) { create(:user, status: :active) }

  context "when unauthenticated" do
    it "returns 401" do
      post "/api/v1/daily_metrics", params: { daily_metric: { weight: 80 } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    context "with valid params and no explicit date" do
      it "returns 200 and creates a metric for today" do
        expect {
          post "/api/v1/daily_metrics",
            params: { daily_metric: { weight: 80.5 } },
            headers: auth_headers(user)
        }.to change(user.daily_metrics, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(user.daily_metrics.last.date_logged).to eq(Date.today)
      end
    end

    context "with an explicit date" do
      let(:target_date) { "2026-01-15" }

      it "returns 200 and creates a metric for that date" do
        post "/api/v1/daily_metrics",
          params: { daily_metric: { weight: 79.0, date_logged: target_date } },
          headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        expect(user.daily_metrics.last.date_logged.to_s).to eq(target_date)
      end
    end

    context "posting the same date twice" do
      let(:target_date) { "2026-02-01" }

      it "updates the existing record (idempotent)" do
        create(:daily_metric, user: user, date_logged: target_date, weight: 75.0)

        expect {
          post "/api/v1/daily_metrics",
            params: { daily_metric: { date_logged: target_date, weight: 76.0 } },
            headers: auth_headers(user)
        }.not_to change(user.daily_metrics, :count)

        expect(response).to have_http_status(:ok)
        expect(user.daily_metrics.find_by(date_logged: target_date).weight).to eq(76.0)
      end
    end

    context "with all permitted params" do
      it "returns 200 and reflects all fields" do
        post "/api/v1/daily_metrics",
          params: {
            daily_metric: {
              date_logged: "2026-03-10",
              weight: 82.5,
              calories_consumed: 2500,
              protein_consumed: 180,
              steps: 8000,
              workout_completed: true
            }
          },
          headers: auth_headers(user)

        expect(response).to have_http_status(:ok)
        metric = user.daily_metrics.last
        expect(metric.calories_consumed).to eq(2500)
        expect(metric.protein_consumed).to eq(180)
        expect(metric.steps).to eq(8000)
        expect(metric.workout_completed).to be(true)
      end
    end

    context "with no daily_metric key at all" do
      it "returns 400 (ParameterMissing)" do
        # params.require(:daily_metric) raises when the key is absent entirely.
        post "/api/v1/daily_metrics",
          params: {},
          headers: auth_headers(user)

        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
