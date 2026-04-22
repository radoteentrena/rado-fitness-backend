require "rails_helper"

RSpec.describe "PUT /api/v1/device_token", type: :request do
  let(:user) { create(:user, status: :active) }

  context "when unauthenticated" do
    it "returns 401" do
      put "/api/v1/device_token", params: { fcm_token: "new_token" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    it "updates fcm_token and returns 204" do
      put "/api/v1/device_token",
        params: { fcm_token: "new_device_token_abc" },
        headers: auth_headers(user)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.fcm_token).to eq("new_device_token_abc")
    end

    it "overwrites an existing fcm_token" do
      user.update!(fcm_token: "old_token")

      put "/api/v1/device_token",
        params: { fcm_token: "refreshed_token" },
        headers: auth_headers(user)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.fcm_token).to eq("refreshed_token")
    end

    it "returns 422 when fcm_token is blank" do
      put "/api/v1/device_token",
        params: { fcm_token: "" },
        headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
