require 'rails_helper'

RSpec.describe 'Api::V1::Messages', type: :request do
  let(:basic_user) { create(:user, plan_tier: :basic) }
  let(:medium_user) { create(:user, plan_tier: :medium) }
  let(:high_user) { create(:user, plan_tier: :high_ticket) }

  describe 'GET /api/v1/messages' do
    context 'Basic tier user' do
      it 'returns 401 Unauthorized' do
        get '/api/v1/messages', headers: auth_headers(basic_user)
        expect(response).to have_http_status(:unauthorized)
        expect(json['error']).to eq('Plan does not include messaging')
      end
    end

    context 'Medium tier user' do
      it 'returns 200 OK with conversation' do
        conversation = create(:conversation, user: medium_user)
        create(:message, conversation: conversation, content: 'Test', sender_type: :coach, user: medium_user)

        get '/api/v1/messages', headers: auth_headers(medium_user)
        expect(response).to have_http_status(:ok)
        expect(json['conversation']['user_id']).to eq(medium_user.id)
        expect(json['messages']).to be_an(Array)
        expect(json['messages'].length).to eq(1)
      end
    end

    context 'High ticket user' do
      it 'returns 200 OK with conversation' do
        conversation = create(:conversation, user: high_user)
        create(:message, conversation: conversation, content: 'Test', sender_type: :coach, user: high_user)

        get '/api/v1/messages', headers: auth_headers(high_user)
        expect(response).to have_http_status(:ok)
        expect(json['conversation']['user_id']).to eq(high_user.id)
      end
    end

    context 'User with no messages' do
      it 'auto-creates conversation and returns empty messages' do
        get '/api/v1/messages', headers: auth_headers(medium_user)
        expect(response).to have_http_status(:ok)
        expect(json['messages']).to be_empty
        expect(medium_user.conversations.count).to eq(1)
      end
    end

    context 'Read status tracking' do
      it 'marks coach messages as read when fetched' do
        conversation = create(:conversation, user: medium_user)
        coach_message = create(:message, conversation: conversation, sender_type: :coach, read_at: nil, user: medium_user)

        get '/api/v1/messages', headers: auth_headers(medium_user)

        coach_message.reload
        expect(coach_message.read_at).to be_present
      end
    end
  end

  describe 'POST /api/v1/messages' do
    context 'Basic tier user' do
      it 'returns 401 Unauthorized' do
        post '/api/v1/messages',
          params: { message: { content: 'Test' } },
          headers: auth_headers(basic_user)
        expect(response).to have_http_status(:unauthorized)
        expect(json['error']).to eq('Plan does not include messaging')
      end
    end

    context 'Medium tier user sends text message' do
      it 'creates message in conversation' do
        expect {
          post '/api/v1/messages',
            params: { message: { content: 'Test message' } },
            headers: auth_headers(medium_user)
        }.to change { Message.count }.by(1)

        expect(response).to have_http_status(:created)
        expect(json['content']).to eq('Test message')
        expect(json['sender_type']).to eq('client')
        expect(json['conversation_id']).to be_present
      end
    end

    context 'High ticket user sends text message' do
      it 'creates message successfully' do
        post '/api/v1/messages',
          params: { message: { content: 'High ticket message' } },
          headers: auth_headers(high_user)
        expect(response).to have_http_status(:created)
      end
    end

    context 'Message validation' do
      it 'rejects empty content and no voice_note' do
        post '/api/v1/messages',
          params: { message: { content: '' } },
          headers: auth_headers(medium_user)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['errors']).to be_present
      end
    end

    context 'Message creation' do
      it 'creates message successfully' do
        post '/api/v1/messages',
          params: { message: { content: 'Test message' } },
          headers: auth_headers(medium_user)
        expect(response).to have_http_status(:created)
        expect(json['content']).to eq('Test message')
        expect(json['sender_type']).to eq('client')
      end

      it 'updates conversation last_message_at when message created' do
        conversation = create(:conversation, user: medium_user, last_message_at: 1.hour.ago)
        old_timestamp = conversation.last_message_at

        post '/api/v1/messages',
          params: { message: { content: 'New message' } },
          headers: auth_headers(medium_user)

        conversation.reload
        expect(conversation.last_message_at).to be > old_timestamp
      end
    end
  end

  private

  def auth_headers(user)
    { 'Authorization' => "Token #{user.auth_token}" }
  end

  def json
    JSON.parse(response.body)
  end
end
