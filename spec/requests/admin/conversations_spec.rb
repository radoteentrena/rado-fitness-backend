require "rails_helper"

RSpec.describe "Admin Conversations", type: :request do
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:client_user) { create(:user) }
  let(:conversation) { create(:conversation, user: client_user) }

  before do
    # Mock authentication
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(admin_user)
  end

  describe "GET #show" do
    it "renders the conversation detail page" do
      get admin_conversation_path(conversation)
      expect(response).to have_http_status(:success)
    end

    it "updates read_by_coach_at timestamp" do
      expect(conversation.read_by_coach_at).to be_nil
      get admin_conversation_path(conversation)
      conversation.reload
      expect(conversation.read_by_coach_at).not_to be_nil
    end

    it "displays conversation messages" do
      message = create(:message, conversation: conversation)
      get admin_conversation_path(conversation)
      expect(response.body).to include(message.content)
    end
  end

  describe "POST #create_message" do
    context "with text message" do
      it "creates a new message" do
        expect {
          post "/admin/conversations/#{conversation.id}/create_message", params: { content: "Test message" }
        }.to change { conversation.messages.count }.by(1)
      end

      it "sets sender_type to coach" do
        post "/admin/conversations/#{conversation.id}/create_message", params: { content: "Test message" }
        message = conversation.messages.last
        expect(message.sender_type).to eq("coach")
      end

      it "redirects to conversation show page" do
        post "/admin/conversations/#{conversation.id}/create_message", params: { content: "Test message" }
        expect(response).to redirect_to(admin_conversation_path(conversation))
      end
    end

    context "with voice data" do
      it "creates a message with voice attachment" do
        voice_data = "data:audio/webm;base64,UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="

        expect {
          post "/admin/conversations/#{conversation.id}/create_message", params: { voice_data: voice_data }
        }.to change { conversation.messages.count }.by(1)
      end

      it "attaches voice note to message" do
        voice_data = "data:audio/webm;base64,UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="
        post "/admin/conversations/#{conversation.id}/create_message", params: { voice_data: voice_data }
        message = conversation.messages.last
        expect(message.voice_note).to be_attached
      end
    end

    context "with invalid data" do
      it "shows error when neither content nor voice data provided" do
        post "/admin/conversations/#{conversation.id}/create_message", params: {}
        expect(response).to redirect_to(admin_conversation_path(conversation))
        expect(flash[:alert]).to include("Error")
      end
    end
  end

  describe "DELETE #delete_message" do
    let(:coach_message) { create(:message, conversation: conversation, sender_type: :coach, content: "Coach reply") }
    let(:client_message) { create(:message, conversation: conversation, sender_type: :client, content: "Client question") }

    context "when deleting coach message" do
      it "soft deletes the coach message" do
        coach_message
        expect {
          delete "/admin/conversations/#{conversation.id}/delete_message", params: { message_id: coach_message.id }
        }.not_to change { conversation.messages.count }

        coach_message.reload
        expect(coach_message.discarded_at).not_to be_nil
      end

      it "redirects to conversation page with success message" do
        coach_message
        delete "/admin/conversations/#{conversation.id}/delete_message", params: { message_id: coach_message.id }
        expect(response).to redirect_to(admin_conversation_path(conversation))
        expect(flash[:notice]).to include("Mensaje eliminado exitosamente")
      end

      it "removes deleted message from not_deleted scope" do
        coach_message
        delete "/admin/conversations/#{conversation.id}/delete_message", params: { message_id: coach_message.id }
        expect(conversation.messages.not_deleted).not_to include(coach_message)
      end
    end

    context "when attempting to delete client message" do
      it "does not delete the message" do
        client_message
        delete "/admin/conversations/#{conversation.id}/delete_message", params: { message_id: client_message.id }
        client_message.reload
        expect(client_message.discarded_at).to be_nil
      end

      it "shows error message" do
        client_message
        delete "/admin/conversations/#{conversation.id}/delete_message", params: { message_id: client_message.id }
        expect(response).to redirect_to(admin_conversation_path(conversation))
        expect(flash[:alert]).to include("No puedes eliminar mensajes del cliente")
      end
    end
  end
end
