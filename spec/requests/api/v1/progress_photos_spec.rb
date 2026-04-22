require 'rails_helper'

RSpec.describe "POST /api/v1/progress_photos", type: :request do
  let(:user) { create(:user, status: :active) }
  let(:image_file) { fixture_file_upload("test.png", "image/png") }

  context "when unauthenticated" do
    it "returns 401" do
      post "/api/v1/progress_photos"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when authenticated" do
    context "with a valid image and date" do
      it "returns 201 with the expected fields" do
        post "/api/v1/progress_photos",
          params: {
            progress_photo: {
              image: image_file,
              date: "2026-03-01",
              note: "Me veo más grande"
            }
          },
          headers: auth_headers(user)

        expect(response).to have_http_status(:created)
        expect(json).to include("id", "date", "note", "image_url")
        expect(json["note"]).to eq("Me veo más grande")
      end
    end

    context "without an image" do
      it "returns 422" do
        post "/api/v1/progress_photos",
          params: { progress_photo: { date: "2026-03-01" } },
          headers: auth_headers(user)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
