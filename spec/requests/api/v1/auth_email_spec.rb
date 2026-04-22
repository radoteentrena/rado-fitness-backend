require 'rails_helper'

RSpec.describe "POST /api/v1/auth/email", type: :request do
  let(:user) { create(:user, status: :active, password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }

  context "with valid credentials" do
    it "returns 200 with auth_token and user info" do
      post "/api/v1/auth/email",
        params: { email: user.email, password: "SecurePassword123!" },
        headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(json).to include("auth_token", "user")
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["auth_token"]).to eq(user.auth_token)
    end
  end

  context "with wrong password" do
    it "returns 401" do
      post "/api/v1/auth/email",
        params: { email: user.email, password: "wrong_password" },
        headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to eq("Invalid email or password")
    end
  end

  context "with non-existent email" do
    it "returns 401" do
      post "/api/v1/auth/email",
        params: { email: "nobody@example.com", password: "SecurePassword123!" },
        headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an inactive user" do
    let(:inactive_user) { create(:user, status: :lead, password: "SecurePassword123!", password_confirmation: "SecurePassword123!") }

    it "returns 401" do
      post "/api/v1/auth/email",
        params: { email: inactive_user.email, password: "SecurePassword123!" },
        headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
