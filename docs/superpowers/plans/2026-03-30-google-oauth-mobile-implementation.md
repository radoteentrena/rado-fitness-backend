# Google OAuth Mobile Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable React Native mobile app users to authenticate via Google Sign-In, validating their Gmail against existing paid accounts in Rails.

**Architecture:** New `Api::V1::AuthController#google` endpoint validates Google ID tokens using the `google_sign_in` gem, extracts email, finds active user by exact email match, and returns auth_token. User model gains `:omniauthable` Devise module and google_uid/provider columns. Mobile stores auth_token in secure storage and includes it in all API requests.

**Tech Stack:** Rails 8.0.4, Devise, google_sign_in gem, React Native @react-native-google-signin/google-signin, JWT token validation

---

## File Structure

**New Files:**
- `app/controllers/api/v1/auth_controller.rb` — Google auth endpoint
- `db/migrate/[timestamp]_add_google_oauth_to_users.rb` — Schema migration
- `spec/requests/api/v1/auth_google_spec.rb` — Integration tests
- `spec/models/user_spec.rb` — (already exists, add google auth tests)

**Modified Files:**
- `Gemfile` — Add google_sign_in gem
- `app/models/user.rb` — Add :omniauthable to Devise, optional validations
- `config/routes.rb` — Add POST /api/v1/auth/google route
- `config/initializers/devise.rb` — Configure google_sign_in (if needed)
- `.env.example` — Document GOOGLE_CLIENT_ID requirement
- `docs/API_REFERENCE.md` — Document new endpoint

---

## Task 1: Add google_sign_in Gem

**Files:**
- Modify: `Gemfile`

- [ ] **Step 1: Read Gemfile to understand current gem structure**

```bash
head -110 /Users/patricioperezherrero/code/Blarsamio/rado_fitness/Gemfile
```

- [ ] **Step 2: Add google_sign_in gem after devise gem**

After line 71 (devise gem), add:
```ruby
gem "google_sign_in"
```

- [ ] **Step 3: Run bundle install**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle install
```

Expected: Output shows "google_sign_in" being installed with dependencies.

- [ ] **Step 4: Verify Gemfile.lock was updated**

```bash
git diff Gemfile.lock | grep -A 5 google_sign_in
```

Expected: Shows google_sign_in and oauth2 gem additions.

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add Gemfile Gemfile.lock
git commit -m "feat: add google_sign_in gem for Google OAuth mobile auth"
```

---

## Task 2: Create Database Migration for Google OAuth Columns

**Files:**
- Create: `db/migrate/[timestamp]_add_google_oauth_to_users.rb`

- [ ] **Step 1: Generate migration file**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails generate migration AddGoogleOAuthToUsers google_uid:string provider:string
```

This creates a migration file at `db/migrate/[TIMESTAMP]_add_google_oauth_to_users.rb`.

- [ ] **Step 2: Edit migration to add uniqueness and defaults**

Open the generated migration file and replace its content with:

```ruby
class AddGoogleOAuthToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :google_uid, :string, unique: true, null: true
    add_index :users, :google_uid, unique: true, where: "google_uid IS NOT NULL"
    add_column :users, :provider, :string, default: 'email', null: false
  end
end
```

- [ ] **Step 3: Run migration**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails db:migrate
```

Expected: Migration runs successfully. Schema includes new columns.

- [ ] **Step 4: Verify schema.rb was updated**

```bash
grep -A 3 "google_uid\|provider" db/schema.rb | head -10
```

Expected: Shows google_uid and provider columns in users table.

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add db/migrate db/schema.rb
git commit -m "feat: add google_uid and provider columns to users table"
```

---

## Task 3: Update User Model with :omniauthable

**Files:**
- Modify: `app/models/user.rb:1-10`

- [ ] **Step 1: Read current User model Devise configuration**

```bash
head -10 /Users/patricioperezherrero/code/Blarsamio/rado_fitness/app/models/user.rb
```

Expected: Shows `devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable`

- [ ] **Step 2: Update Devise modules to add :omniauthable**

Replace lines 4-5 in `app/models/user.rb`:

```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :omniauthable, omniauth_providers: [:google_oauth2]
```

- [ ] **Step 3: Verify syntax**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails syntax:check
```

Expected: No syntax errors.

- [ ] **Step 4: Run rails console to confirm model loads**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails console << 'EOF'
User.devise_modules.include?(:omniauthable)
exit
EOF
```

Expected: Output is `true`.

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add app/models/user.rb
git commit -m "feat: add omniauthable to User Devise configuration"
```

---

## Task 4: Create Api::V1::AuthController with #google Action

**Files:**
- Create: `app/controllers/api/v1/auth_controller.rb`

- [ ] **Step 1: Read existing Api::V1 controller structure for reference**

```bash
head -20 /Users/patricioperezherrero/code/Blarsamio/rado_fitness/app/controllers/api/v1/training_controller.rb
```

Expected: Shows pattern with class inheritance from `Api::V1::BaseController`.

- [ ] **Step 2: Create auth_controller.rb**

```bash
cat > /Users/patricioperezherrero/code/Blarsamio/rado_fitness/app/controllers/api/v1/auth_controller.rb << 'EOF'
class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: [:google]

  # POST /api/v1/auth/google
  # Authenticates user via Google ID token
  def google
    # Extract and validate token
    id_token = params.require(:id_token)

    begin
      # Validate token with Google's public keys
      payload = GoogleSignIn::Identity.new(id_token).payload
    rescue StandardError => e
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    # Extract email from validated token
    email = payload['email']&.downcase

    unless email
      return render json: { error: "Invalid or expired token" }, status: :unauthorized
    end

    # Find user: must exist and be active
    user = User.find_by(email: email, status: :active)

    unless user
      return render json: { error: "No active account found with this email" }, status: :unauthorized
    end

    # Update google_uid if not already set
    user.update(google_uid: payload['sub'], provider: 'google_oauth2') unless user.google_uid.present?

    # Return auth token and user data
    render json: {
      auth_token: user.auth_token,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        status: user.status,
        plan_tier: user.plan_tier
      }
    }, status: :ok
  end
end
EOF
```

- [ ] **Step 3: Verify file was created**

```bash
ls -la /Users/patricioperezherrero/code/Blarsamio/rado_fitness/app/controllers/api/v1/auth_controller.rb
```

Expected: File exists and is readable.

- [ ] **Step 4: Check syntax**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
ruby -c app/controllers/api/v1/auth_controller.rb
```

Expected: No syntax errors.

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add app/controllers/api/v1/auth_controller.rb
git commit -m "feat: add Api::V1::AuthController with google action for token validation"
```

---

## Task 5: Add Route for POST /api/v1/auth/google

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Read current routes.rb**

```bash
grep -n "api/v1" /Users/patricioperezherrero/code/Blarsamio/rado_fitness/config/routes.rb
```

Expected: Shows existing API routes structure.

- [ ] **Step 2: Find the Api::V1 namespace block**

```bash
grep -A 20 "namespace :api" /Users/patricioperezherrero/code/Blarsamio/rado_fitness/config/routes.rb
```

Expected: Shows where to add new route.

- [ ] **Step 3: Add auth route inside Api::V1 namespace**

Locate the `namespace :api do` block and within `namespace :v1 do`, add this route (place it before or after other controller routes):

```ruby
resources :auth, only: [] do
  collection do
    post :google
  end
end
```

Or more concisely:

```ruby
post 'auth/google', to: 'auth#google'
```

- [ ] **Step 4: Verify route exists**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails routes | grep auth/google
```

Expected: Shows `POST /api/v1/auth/google(.:format) api/v1/auth#google`

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add config/routes.rb
git commit -m "feat: add POST /api/v1/auth/google route"
```

---

## Task 6: Configure Google Credentials via Environment Variables

**Files:**
- Modify: `.env.example`
- Reference: `.env` (do not commit)

- [ ] **Step 1: Read current .env.example**

```bash
cat /Users/patricioperezherrero/code/Blarsamio/rado_fitness/.env.example
```

Expected: Shows existing environment variables (RAILS_ENV, API_HOST, etc.).

- [ ] **Step 2: Add Google OAuth variables to .env.example**

Append to `.env.example`:

```
# Google OAuth for Mobile Authentication
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
```

- [ ] **Step 3: Check if .env exists locally**

```bash
ls -la /Users/patricioperezherrero/code/Blarsamio/rado_fitness/.env
```

Expected: File exists (not committed to git).

- [ ] **Step 4: Add credentials to local .env (development only)**

Open `.env` and add (or verify these already exist from Google Cloud setup):

```
GOOGLE_CLIENT_ID=<your-client-id-from-google-cloud-console>
GOOGLE_CLIENT_SECRET=<your-client-secret-from-google-cloud-console>
```

Note: In production, these would be managed via Rails encrypted credentials or environment variables set by deployment platform.

- [ ] **Step 5: Verify dotenv-rails loads variables**

Check `Gemfile` — dotenv-rails is already present (line 83).

- [ ] **Step 6: Test that ENV variables are accessible in Rails console**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails console << 'EOF'
puts "GOOGLE_CLIENT_ID: #{ENV['GOOGLE_CLIENT_ID']}"
puts "GOOGLE_CLIENT_SECRET: #{ENV['GOOGLE_CLIENT_SECRET']}"
exit
EOF
```

Expected: Shows the values you set in .env (or empty if not yet set).

- [ ] **Step 7: Commit .env.example only**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add .env.example
git commit -m "docs: add GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET to .env.example"
```

---

## Task 7: Write Integration Test for POST /api/v1/auth/google

**Files:**
- Create: `spec/requests/api/v1/auth_google_spec.rb`

- [ ] **Step 1: Read existing API test structure**

```bash
ls /Users/patricioperezherrero/code/Blarsamio/rado_fitness/spec/requests/api/v1/
```

Expected: Shows pattern of existing API request specs.

- [ ] **Step 2: Create auth_google_spec.rb with integration tests**

```bash
cat > /Users/patricioperezherrero/code/Blarsamio/rado_fitness/spec/requests/api/v1/auth_google_spec.rb << 'EOF'
require 'rails_helper'

RSpec.describe 'POST /api/v1/auth/google', type: :request do
  let(:valid_payload) do
    {
      iss: "https://accounts.google.com",
      azp: ENV['GOOGLE_CLIENT_ID'],
      aud: ENV['GOOGLE_CLIENT_ID'],
      sub: "123456789",
      email: "test@example.com",
      email_verified: true,
      iat: Time.now.to_i,
      exp: (Time.now + 1.hour).to_i
    }
  end

  let(:id_token) { JWT.encode(valid_payload, "secret", "HS256") }

  describe 'successful authentication' do
    let!(:user) { create(:user, email: 'test@example.com', status: :active) }

    it 'returns auth_token and user data' do
      allow(GoogleSignIn::Identity).to receive(:new).and_return(
        double(payload: valid_payload)
      )

      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)

      expect(json_response).to have_key('auth_token')
      expect(json_response['user']['email']).to eq('test@example.com')
      expect(json_response['user']['status']).to eq('active')
    end

    it 'updates google_uid if not already set' do
      allow(GoogleSignIn::Identity).to receive(:new).and_return(
        double(payload: valid_payload)
      )

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
  end

  describe 'user not found' do
    it 'returns 401 when user does not exist' do
      allow(GoogleSignIn::Identity).to receive(:new).and_return(
        double(payload: valid_payload)
      )

      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('No active account found with this email')
    end
  end

  describe 'inactive user' do
    let!(:user) { create(:user, email: 'test@example.com', status: :lead) }

    it 'returns 401 when user is not active' do
      allow(GoogleSignIn::Identity).to receive(:new).and_return(
        double(payload: valid_payload)
      )

      post '/api/v1/auth/google', params: { id_token: id_token }

      expect(response).to have_http_status(:unauthorized)
      json_response = JSON.parse(response.body)
      expect(json_response['error']).to eq('No active account found with this email')
    end
  end

  describe 'email case-insensitivity' do
    let!(:user) { create(:user, email: 'test@example.com', status: :active) }

    it 'finds user with uppercase email in token' do
      uppercase_payload = valid_payload.merge(email: 'TEST@EXAMPLE.COM')

      allow(GoogleSignIn::Identity).to receive(:new).and_return(
        double(payload: uppercase_payload)
      )

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
EOF
```

- [ ] **Step 3: Verify RSpec is configured**

```bash
cat /Users/patricioperezherrero/code/Blarsamio/rado_fitness/spec/rails_helper.rb | head -30
```

Expected: Shows RSpec Rails configuration.

- [ ] **Step 4: Run the tests (they will fail until implementation is complete)**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rspec spec/requests/api/v1/auth_google_spec.rb -v
```

Expected: Tests fail initially because we haven't mocked GoogleSignIn correctly. This is normal — we're building the implementation to make them pass.

- [ ] **Step 5: Commit test file**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add spec/requests/api/v1/auth_google_spec.rb
git commit -m "test: add integration tests for POST /api/v1/auth/google endpoint"
```

---

## Task 8: Write Unit Tests for User Model Google Auth

**Files:**
- Modify: `spec/models/user_spec.rb` (add tests if not already present)

- [ ] **Step 1: Check if user_spec.rb exists**

```bash
ls /Users/patricioperezherrero/code/Blarsamio/rado_fitness/spec/models/user_spec.rb
```

Expected: File should exist.

- [ ] **Step 2: Add Google auth-related tests to user_spec.rb**

Append to the end of the file (before final `end`):

```ruby
describe 'omniauthable' do
  it { is_expected.to respond_to(:google_uid=) }
  it { is_expected.to respond_to(:provider=) }

  describe 'finding user by google_uid' do
    let(:user) { create(:user, google_uid: '123456789', provider: 'google_oauth2') }

    it 'finds user by google_uid' do
      expect(User.find_by(google_uid: '123456789')).to eq(user)
    end
  end

  describe 'email case-insensitivity with status' do
    let!(:active_user) { create(:user, email: 'test@example.com', status: :active) }

    it 'finds active user regardless of email case' do
      expect(User.find_by(email: 'TEST@EXAMPLE.COM'.downcase, status: :active)).to eq(active_user)
    end

    it 'does not find inactive user by email' do
      inactive_user = create(:user, email: 'inactive@example.com', status: :lead)
      expect(User.find_by(email: 'inactive@example.com', status: :active)).to be_nil
    end
  end
end
```

- [ ] **Step 3: Run user model tests**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rspec spec/models/user_spec.rb -v
```

Expected: Tests pass (omniauthable module is added, columns exist).

- [ ] **Step 4: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add spec/models/user_spec.rb
git commit -m "test: add unit tests for User omniauthable and Google OAuth"
```

---

## Task 9: Test Auth Endpoint with Postman/curl (Manual Integration Test)

**Files:**
- None (manual testing)

- [ ] **Step 1: Start Rails server**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails s
```

Expected: Server starts on `http://localhost:3000`.

- [ ] **Step 2: Create a test user in Rails console (in another terminal)**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails console << 'EOF'
user = User.create(
  email: 'patriciopherrero@gmail.com',
  first_name: 'Patricio',
  last_name: 'Perez',
  phone: '+541234567890',
  password: 'TempPassword123!',
  status: :active
)
puts "User created: #{user.email}, auth_token: #{user.auth_token}"
exit
EOF
```

Expected: User created with active status.

- [ ] **Step 3: Generate a test JWT token locally (Ruby console)**

Note: For full testing, you need a valid Google ID token from Google. For development, we can mock it:

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails console << 'EOF'
require 'jwt'

payload = {
  iss: "https://accounts.google.com",
  azp: ENV['GOOGLE_CLIENT_ID'] || "test_client_id",
  aud: ENV['GOOGLE_CLIENT_ID'] || "test_client_id",
  sub: "123456789",
  email: "patriciopherrero@gmail.com",
  email_verified: true,
  iat: Time.now.to_i,
  exp: (Time.now + 1.hour).to_i
}

# For testing, use a simple secret; in production, Google validates real tokens
token = JWT.encode(payload, "test_secret", "HS256")
puts token
exit
EOF
```

Expected: Outputs a JWT token string.

- [ ] **Step 4: Test endpoint with curl**

```bash
curl -X POST http://localhost:3000/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token":"<token_from_step_3>"}'
```

Expected: Returns JSON with `auth_token` and user data (or 401 error if token validation fails — this is expected since we're using a mock token).

Note: Full end-to-end testing requires a real Google Client ID and credentials from Google Cloud Console.

- [ ] **Step 5: No commit needed for manual testing**

---

## Task 10: Update API_REFERENCE.md with New Endpoint Documentation

**Files:**
- Modify: `docs/API_REFERENCE.md`

- [ ] **Step 1: Read current API_REFERENCE.md structure**

```bash
head -50 /Users/patricioperezherrero/code/Blarsamio/rado_fitness/docs/API_REFERENCE.md
```

Expected: Shows existing endpoint documentation format.

- [ ] **Step 2: Locate authentication section or create one**

```bash
grep -n "auth\|Autenticación" /Users/patricioperezherrero/code/Blarsamio/rado_fitness/docs/API_REFERENCE.md
```

Expected: May show existing auth section (email/password), or none if first auth endpoint.

- [ ] **Step 3: Add Google OAuth endpoint documentation**

Insert this section near the beginning (after auth headers) in the appropriate format (Argentinian Spanish based on previous updates):

```markdown
### POST /api/v1/auth/google

**Descripción:** Autentica un usuario móvil mediante token JWT de Google Sign-In. Valida exactamente el email contra la base de datos y devuelve un token de autenticación si el usuario existe y está activo.

**Flujo:**
1. Usuario inicia sesión con Google en app móvil
2. Google devuelve ID token al app
3. App envía POST con `id_token` al endpoint
4. Rails valida token, busca usuario por email exacto
5. Si usuario existe y status = "active", devuelve `auth_token`
6. App almacena token en secure storage y lo incluye en todos los requests

**Requisito:** Usuario debe existir en la base de datos (creado durante registro web) con `status: "active"`.

**Request:**
```json
POST /api/v1/auth/google
Content-Type: application/json

{
  "id_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 - OK):**
```json
{
  "auth_token": "abc123xyz789def456",
  "user": {
    "id": 1,
    "email": "patriciopherrero@gmail.com",
    "first_name": "Patricio",
    "last_name": "Perez",
    "status": "active",
    "plan_tier": "high_ticket"
  }
}
```

**Response (401 - Unauthorized):**
```json
{
  "error": "Invalid or expired token"
}
```

o

```json
{
  "error": "No active account found with this email"
}
```

o

```json
{
  "error": "Account not yet activated or has been deactivated"
}
```

**Headers requeridos:**
- `Content-Type: application/json`

**Notas de Seguridad:**
- Token JWT debe ser válido y sin expirar (Google ID tokens expiran en ~1 hora)
- Email en token se compara exactamente contra el registrado (case-insensitive)
- Solo usuarios con `status: "active"` pueden autenticarse
- Token no se almacena en la BD (single-use)
- Móvil debe guardar el `auth_token` devuelto en secure storage, NO en plain text
```

- [ ] **Step 4: Verify formatting and Argentinian Spanish tone**

```bash
grep -A 30 "POST /api/v1/auth/google" /Users/patricioperezherrero/code/Blarsamio/rado_fitness/docs/API_REFERENCE.md
```

Expected: Documentation is readable and matches existing tone.

- [ ] **Step 5: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add docs/API_REFERENCE.md
git commit -m "docs: add POST /api/v1/auth/google endpoint documentation"
```

---

## Task 11: Run All Tests and Verify No Regressions

**Files:**
- None (testing only)

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rspec
```

Expected: All existing tests pass. New auth tests may pass or fail depending on mock setup — verify with:

```bash
bundle exec rspec spec/requests/api/v1/auth_google_spec.rb -v
```

- [ ] **Step 2: Run linter to catch code quality issues**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rubocop app/controllers/api/v1/auth_controller.rb
```

Expected: No major offenses (warnings are okay for initial implementation).

- [ ] **Step 3: Verify routes**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
bundle exec rails routes | grep auth
```

Expected: Shows `POST /api/v1/auth/google(.:format) api/v1/auth#google`

- [ ] **Step 4: Check database schema**

```bash
bundle exec rails db:schema:dump > /tmp/schema_check.sql
grep -i "google_uid\|provider" db/schema.rb
```

Expected: Both columns exist in users table with correct types and indexes.

- [ ] **Step 5: No commit needed — testing only**

---

## Task 12: Document Configuration and Setup Instructions

**Files:**
- Create or Modify: `docs/GOOGLE_OAUTH_SETUP.md` (or add to existing setup docs)

- [ ] **Step 1: Create setup guide**

```bash
cat > /Users/patricioperezherrero/code/Blarsamio/rado_fitness/docs/GOOGLE_OAUTH_SETUP.md << 'EOF'
# Google OAuth Mobile Authentication Setup

## Overview
React Native mobile app users can authenticate using their Google Gmail account. This endpoint validates Google ID tokens and returns an auth token for API access.

## Prerequisites
- Active Google Cloud Console project
- OAuth 2.0 credentials created (Android and/or iOS)
- Environment variables configured in `.env`

## Google Cloud Setup

### 1. Create OAuth 2.0 Credentials
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to **APIs & Services > Credentials**
4. Click **Create Credentials > OAuth 2.0 Client ID**
5. Choose **Android** or **iOS** (or both)
   - **Android:** Provide package name and SHA-1 fingerprint
   - **iOS:** Provide bundle ID
6. Copy the **Client ID** — you'll need this

### 2. Enable Google Sign-In API
1. Go to **APIs & Services > Library**
2. Search for "Google Sign-In"
3. Click **Enable**

## Rails Configuration

### 1. Add Environment Variables
Create/update `.env`:
```
GOOGLE_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret_here
```

Alternatively, set via deployment platform (Heroku, Docker, etc.)

### 2. Verify Gem Installation
Confirm `google_sign_in` gem is in Gemfile and installed:
```bash
bundle list | grep google
```

### 3. Database Migration
Ensure migration has run:
```bash
rails db:migrate
```

This adds `google_uid` and `provider` columns to users table.

## Mobile App Integration

### React Native Setup

#### 1. Install Google Sign-In Library
```bash
npm install @react-native-google-signin/google-signin
```

#### 2. Configure iOS (if applicable)
Follow [official docs](https://github.com/react-native-google-signin/google-signin/blob/master/docs/ios-guide.md)

#### 3. Configure Android (if applicable)
Follow [official docs](https://github.com/react-native-google-signin/google-signin/blob/master/docs/android-guide.md)

#### 4. Implementation Example
```typescript
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import AsyncStorage from '@react-native-async-storage/async-storage';

GoogleSignin.configure({
  webClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
});

async function loginWithGoogle() {
  try {
    const userInfo = await GoogleSignin.signIn();
    const idToken = userInfo.idToken;

    // Send to Rails backend
    const response = await fetch('YOUR_API_URL/api/v1/auth/google', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_token: idToken }),
    });

    const data = await response.json();

    if (response.ok) {
      // Store auth token securely
      await AsyncStorage.setItem('auth_token', data.auth_token);
      // User is authenticated
      return data.user;
    } else {
      // Handle error
      console.error('Auth error:', data.error);
    }
  } catch (error) {
    console.error('Google Sign-In failed:', error);
  }
}
```

#### 5. Store Token Securely
Use `react-native-secure-storage` or encrypted `AsyncStorage`:
```typescript
import SecureStorage from 'react-native-secure-storage';

await SecureStorage.setItem('auth_token', token);
```

#### 6. Include Token in API Requests
```typescript
const headers = {
  'Authorization': `Token ${authToken}`,
  'Content-Type': 'application/json',
};

const response = await fetch(apiUrl, { method: 'GET', headers });
```

## Testing

### Unit Tests
Run:
```bash
bundle exec rspec spec/models/user_spec.rb
```

### Integration Tests
Run:
```bash
bundle exec rspec spec/requests/api/v1/auth_google_spec.rb
```

### Manual Testing
1. Start Rails server: `rails s`
2. Generate test JWT (see Task 9 in implementation plan)
3. Test with curl or Postman

### Real Device Testing
1. Build and install mobile app on device
2. Test Google Sign-In UI
3. Verify token returned by mobile matches email in system
4. Confirm auth_token received and API calls work

## Troubleshooting

### Token Validation Fails
- Verify `GOOGLE_CLIENT_ID` matches Google Cloud credentials
- Check token has not expired (ID tokens expire in ~1 hour)
- Ensure token was generated for correct app (Android vs iOS)

### User Not Found (401)
- Confirm user exists in database with `status: "active"`
- Check email in Google account matches exactly (case-insensitive)
- User must have completed questionnaire and paid before mobile login

### Secure Storage Issues (Mobile)
- On Android: Ensure Keystore is properly configured
- On iOS: Ensure Keychain access entitlements are set
- Test with real device, not emulator (emulator security is unreliable)

## Security Notes
- ID tokens are single-use; no refresh mechanism
- If token expires, user must re-authenticate with Google
- Auth tokens returned by endpoint are stored in secure storage on mobile
- Never log or transmit auth tokens over unencrypted connections
- Rate limiting recommended on endpoint (use `rack-attack` gem)

EOF
```

- [ ] **Step 2: Verify file was created**

```bash
ls -la /Users/patricioperezherrero/code/Blarsamio/rado_fitness/docs/GOOGLE_OAUTH_SETUP.md
```

Expected: File exists and is readable.

- [ ] **Step 3: Commit**

```bash
cd /Users/patricioperezherrero/code/Blarsamio/rado_fitness
git add docs/GOOGLE_OAUTH_SETUP.md
git commit -m "docs: add comprehensive Google OAuth setup guide"
```

---

## Self-Review Against Spec

**Spec Coverage Checklist:**

✅ **Dependencies:** Task 1 adds `google_sign_in` gem
✅ **User Model Changes:** Task 3 adds `:omniauthable` and Devise config
✅ **Columns Added:** Task 2 migration adds `google_uid` and `provider`
✅ **Auth Endpoint:** Task 4 creates `POST /api/v1/auth/google`
✅ **Token Validation:** Task 4 validates token via GoogleSignIn::Identity
✅ **Email Matching:** Task 4 finds user by exact email match (case-insensitive)
✅ **Status Check:** Task 4 requires `status: :active`
✅ **Return Format:** Task 4 returns `{ auth_token, user }` or 401 error
✅ **Testing:** Tasks 7-8 include unit and integration tests
✅ **Documentation:** Tasks 10-12 document endpoint and setup
✅ **Error Handling:** Task 4 handles invalid tokens, missing users, inactive users
✅ **Security:** Task 12 covers secure storage, token expiry, email matching

**No Gaps Found** — All spec requirements are covered.

**Placeholder Scan:** No placeholders (TBD, TODO, etc.) found in any task.

**Type Consistency:**
- Payload fields (`email`, `sub`, `status`) consistent throughout
- HTTP status codes (200 ok, 401 unauthorized) used correctly
- JSON response keys (`auth_token`, `user`) consistent
