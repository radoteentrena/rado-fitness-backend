require "rails_helper"

RSpec.describe "Complete Messaging Flow", type: :request do
  let(:client_user) { create(:user, plan_tier: :medium, first_name: "Juan", last_name: "Perez") }
  let(:other_user) { create(:user, plan_tier: :basic) }
  let(:admin_user) { create(:user, email: "admin@example.com") }

  def auth_headers(user)
    { "Authorization" => "Token #{user.auth_token}" }
  end

  def json
    JSON.parse(response.body)
  end

  before do
    # Mock authentication for admin panel
    allow_any_instance_of(Admin::ApplicationController).to receive(:authenticate_admin).and_return(true)
    allow_any_instance_of(Admin::ApplicationController).to receive(:current_user).and_return(admin_user)
  end

  describe "Complete user-coach messaging workflow" do
    it "enables full conversation flow from user question to coach reply" do
      # ===== PHASE 1: USER SENDS MESSAGE VIA API =====
      expect {
        post "/api/v1/messages",
             headers: auth_headers(client_user),
             params: {
               message: {
                 content: "¿Cuál es el peso recomendado para el ejercicio de mañana?"
               }
             }
      }.to enqueue_job(NotifyCoachOfNewMessageJob)

      expect(response).to have_http_status(:created)
      user_message_id = json["id"]
      conversation_id = json["conversation_id"]

      # Verify message created
      user_message = Message.find(user_message_id)
      expect(user_message.sender_type).to eq("client")
      conversation = Conversation.find(conversation_id)
      expect(conversation.user_id).to eq(client_user.id)

      # ===== PHASE 2: COACH VIEWS CONVERSATION =====
      get "/admin/conversations/#{conversation_id}"
      expect(response).to have_http_status(:success)

      conversation.reload
      expect(conversation.read_by_coach_at).to be_present

      # ===== PHASE 3: COACH REPLIES WITH TEXT =====
      expect {
        post "/admin/conversations/#{conversation_id}/create_message",
             params: {
               content: "Usa 20kg para este ejercicio"
             }
      }.to enqueue_job(NotifyUserOfCoachReplyJob)

      expect(response).to redirect_to(admin_conversation_path(conversation))

      coach_reply = conversation.messages.where(sender_type: :coach).first
      expect(coach_reply.content).to eq("Usa 20kg para este ejercicio")

      # ===== PHASE 4: USER FETCHES MESSAGES =====
      get "/api/v1/messages",
          headers: auth_headers(client_user)

      expect(response).to have_http_status(:success)
      messages = json["messages"]
      expect(messages.length).to eq(2)

      expect(messages[0]["sender_type"]).to eq("client")
      expect(messages[1]["sender_type"]).to eq("coach")
      expect(messages[1]["read_at"]).to be_present

      # ===== PHASE 5: COACH SENDS VOICE MESSAGE =====
      voice_data = "data:audio/webm;base64,UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="

      post "/admin/conversations/#{conversation_id}/create_message",
           params: {
             voice_data: voice_data
           }

      expect(response).to redirect_to(admin_conversation_path(conversation))

      voice_message = conversation.messages.where(sender_type: :coach).last
      expect(voice_message.voice_note).to be_attached

      # ===== PHASE 6: USER SEES VOICE MESSAGE =====
      get "/api/v1/messages",
          headers: auth_headers(client_user)

      response_json = JSON.parse(response.body)
      messages = response_json["messages"]

      voice_msg_json = messages.find { |m| m["sender_type"] == "coach" && m["voice_note_url"].present? }
      expect(voice_msg_json).to be_present

      # ===== PHASE 7: COACH DELETES A MESSAGE =====
      expect {
        delete "/admin/conversations/#{conversation_id}/delete_message",
               params: { message_id: coach_reply.id }
      }.not_to change { conversation.messages.count }

      expect(response).to redirect_to(admin_conversation_path(conversation))

      coach_reply.reload
      expect(coach_reply.discarded_at).to be_present

      # ===== PHASE 8: USER NO LONGER SEES DELETED MESSAGE =====
      get "/api/v1/messages",
          headers: auth_headers(client_user)

      response_json = JSON.parse(response.body)
      messages = response_json["messages"]

      expect(messages.map { |m| m["id"] }).not_to include(coach_reply.id)

      # ===== PHASE 9: BASIC TIER USER CANNOT ACCESS =====
      get "/api/v1/messages",
          headers: auth_headers(other_user)

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to include("Plan does not include messaging")

      # ===== PHASE 10: VERIFY NOTIFICATIONS =====
      # Perform the enqueued jobs so notifications are created
      perform_enqueued_jobs

      notifications = conversation.reload.notifications
      expect(notifications.count).to be >= 2
      expect(notifications.map(&:notification_type)).to include("new_message", "coach_reply")
    end
  end

  describe "Edge cases and error handling" do
    let(:conversation) { create(:conversation, user: client_user) }

    it "prevents users from deleting messages" do
      client_message = create(:message, conversation: conversation, sender_type: :client)

      delete "/admin/conversations/#{conversation.id}/delete_message",
             params: { message_id: client_message.id }

      expect(response).to redirect_to(admin_conversation_path(conversation))
      expect(flash[:alert]).to include("No puedes eliminar mensajes del cliente")

      client_message.reload
      expect(client_message.discarded_at).to be_nil
    end

    it "handles voice message without text content" do
      voice_data = "data:audio/webm;base64,UklGRiYAAABXQVZFZm10IBAAAAABAAEAQB8AAAB9AAACABAAZGF0YQIAAAAAAA=="

      post "/admin/conversations/#{conversation.id}/create_message",
           params: {
             voice_data: voice_data
           }

      voice_message = conversation.messages.last
      expect(voice_message.voice_note).to be_attached
      expect(voice_message.content).to be_nil
      expect(voice_message.sender_type).to eq("coach")
    end

    it "prevents creating message without content or voice" do
      post "/api/v1/messages",
           headers: auth_headers(client_user),
           params: {
             message: {}
           }

      # Rails returns 400 for missing required parameters, 422 for validation errors
      expect(response).to have_http_status(:bad_request)
    end

    it "maintains read status correctly" do
      user_msg = create(:message, conversation: conversation, sender_type: :client)
      coach_msg = create(:message, conversation: conversation, sender_type: :coach)

      expect(conversation.read_by_coach_at).to be_nil

      get "/admin/conversations/#{conversation.id}"

      conversation.reload
      expect(conversation.read_by_coach_at).to be_present

      get "/api/v1/messages",
          headers: auth_headers(client_user)

      coach_msg.reload
      expect(coach_msg.read_at).to be_present
    end
  end
end
