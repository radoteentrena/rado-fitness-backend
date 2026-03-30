require 'rails_helper'

RSpec.describe 'POST /api/v1/auth/google', type: :request do
  let(:valid_payload) do
    {
      "iss" => "https://accounts.google.com",
      "azp" => ENV['GOOGLE_CLIENT_ID'],
      "aud" => ENV['GOOGLE_CLIENT_ID'],
      "sub" => "123456789",
      "email" => "test@example.com",
      "email_verified" => true,
      "iat" => Time.now.to_i,
      "exp" => (Time.now + 1.hour).to_i
    }
  end

  let(:id_token) { "test_token_123" }

  describe 'successful authentication' do
    let!(:user) { create(:user, email: 'test@example.com', status: :active) }

    before do
      identity_double = double('GoogleSignIn::Identity', payload: valid_payload)
      allow(GoogleSignIn::Identity).to receive(:new).and_return(identity_double)
    end

    it 'returns auth_token and user data' do
      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key('auth_token')
      expect(json_response['user']['email']).to eq('test@example.com')
      expect(json_response['user']['status']).to eq('active')
    end

    it 'updates google_uid if not already set' do
      post '/api/v1/auth/google', params: { id_token: id_token }

      user.reload
      expect(user.google_uid).to eq('123456789')
      expect(user.provider).to eq('google_oauth2')
    end
  end

  describe 'invalid token' do
    it 'returns 401 when token is invalid' do
      allow(GoogleSignIn::Identity).to receive(:new).and_raise(StandardError.new('Invalid token'))

      post '/api/v1/auth/google', params: { id_token: 'invalid_token' }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Invalid or expired token')
    end

    it 'returns 401 when token payload has no email' do
      identity_double = double('GoogleSignIn::Identity', payload: { "sub" => "123" })
      allow(GoogleSignIn::Identity).to receive(:new).and_return(identity_double)

      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('Invalid or expired token')
    end
  end

  describe 'user not found' do
    before do
      identity_double = double('GoogleSignIn::Identity', payload: valid_payload)
      allow(GoogleSignIn::Identity).to receive(:new).and_return(identity_double)
    end

    it 'returns 401 when user does not exist' do
      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('No active account found with this email')
    end
  end

  describe 'inactive user' do
    let!(:user) { create(:user, email: 'test@example.com', status: :lead) }

    before do
      identity_double = double('GoogleSignIn::Identity', payload: valid_payload)
      allow(GoogleSignIn::Identity).to receive(:new).and_return(identity_double)
    end

    it 'returns 401 when user is not active' do
      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('No active account found with this email')
    end
  end

  describe 'email case-insensitivity' do
    let!(:user) { create(:user, email: 'test@example.com', status: :active) }

    it 'finds user with uppercase email in token' do
      uppercase_payload = valid_payload.merge("email" => 'TEST@EXAMPLE.COM')
      identity_double = double('GoogleSignIn::Identity', payload: uppercase_payload)
      allow(GoogleSignIn::Identity).to receive(:new).and_return(identity_double)

      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['user']['email']).to eq('test@example.com')
    end
  end

  describe 'missing id_token' do
    it 'returns 400 when id_token is missing' do
      post '/api/v1/auth/google', params: {}

      expect(response).to have_http_status(:bad_request)
    end
  end
end
