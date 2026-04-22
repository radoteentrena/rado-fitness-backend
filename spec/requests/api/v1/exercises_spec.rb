require 'rails_helper'

RSpec.describe "GET /api/v1/exercises", type: :request do
  let(:user) { create(:user, status: :active) }

  context "when unauthenticated" do
    it "returns 401" do
      get "/api/v1/exercises"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    context "with no exercises in the database" do
      it "returns 200 with an empty array" do
        get "/api/v1/exercises", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json).to eq([])
      end
    end

    context "with exercises in the database" do
      let!(:exercise) { create(:exercise, name: "Squat", muscle_group: "Legs") }

      it "returns 200 with the exercise list" do
        get "/api/v1/exercises", headers: auth_headers(user)
        expect(response).to have_http_status(:ok)
        expect(json).to be_an(Array)
        expect(json.length).to eq(1)
      end

      it "includes expected fields on each exercise" do
        get "/api/v1/exercises", headers: auth_headers(user)
        item = json.first
        expect(item).to include("id", "name", "muscle_group")
      end
    end
  end
end
