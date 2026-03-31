# Google OAuth Mobile Authentication Design

**Date:** March 30, 2026
**Status:** Design Review
**Scope:** Mobile app Google Sign-In integration with Devise

---

## Overview

Implement Google authentication for the React Native mobile app, allowing clients to log in with their Gmail immediately after purchasing a coaching program. Rails validates the Google token and email against the user database, returning an auth token for API access.

---

## User Flow

1. User completes questionnaire on web
2. User pays for service plan → account created with `status: "active"`
3. User receives link to download mobile app
4. User opens app and chooses login method:
   - **Option A:** Google Sign-In (primary) → sends Google ID token to Rails
   - **Option B:** Email/password (fallback) → existing flow
5. Rails validates token or credentials
6. If valid and user is active, returns `auth_token`
7. Mobile stores token and uses it for all subsequent API calls

---

## Architecture

### Google Token Validation
- React Native app uses `@react-native-google-signin/google-signin` library
- Google returns an ID token (JWT) to the mobile app
- Mobile sends token to new endpoint: `POST /api/v1/auth/google`
- Rails validates token signature with Google's public keys using `google_sign_in` gem
- Rails extracts email from validated token
- Rails finds user by exact email match AND `status == "active"`
- If found, returns `auth_token` and user data
- If not found or user inactive, returns 401 error

### Email/Password Flow (Unchanged)
- Existing Devise flow continues to work
- Returns same `auth_token` format
- Mobile can use this as fallback if Google sign-in fails

### Session Management
- Mobile stores `auth_token` in secure storage (not plain text)
- Token included in all subsequent API requests: `Authorization: Token <auth_token>`
- Logout clears token from secure storage

---

## Implementation Components

### 1. Dependencies
Add to Gemfile:
```ruby
gem 'google_sign_in'  # Validates Google ID tokens, integrates with Devise
```

### 2. User Model Changes
Enable omniauthable in Devise:
```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :omniauthable, omniauth_providers: [:google_oauth2]
```

Add optional columns to users table (migration):
```ruby
add_column :users, :google_uid, :string, unique: true, null: true
add_column :users, :provider, :string, default: 'email'
```

These columns allow linking Google to existing email/password accounts in the future.

### 3. New API Endpoint

**Route:** `POST /api/v1/auth/google`

**Request:**
```json
{
  "id_token": "<google_jwt_token>"
}
```

**Response (Success - 200/201):**
```json
{
  "auth_token": "abc123xyz789",
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

**Response (Error - 401):**
```json
{
  "error": "Invalid or expired token"
}
```

OR

```json
{
  "error": "No active account found with this email"
}
```

### 4. Controller Implementation

New file: `app/controllers/api/v1/auth_controller.rb`

Logic:
1. Accept `id_token` parameter
2. Validate token using `google_sign_in` gem
3. Extract email from token payload
4. Query: `User.find_by(email: email, status: :active)`
5. If found: return `auth_token` + user data
6. If not found: return 401 "No active account with this email"
7. If token invalid/expired: return 401 "Invalid or expired token"

---

## Error Handling

| Error | HTTP Status | Message |
|-------|------------|---------|
| Invalid/expired token | 401 | "Invalid or expired token" |
| Email not in system | 401 | "No active account with this email" |
| User exists but status ≠ "active" | 401 | "Account not yet activated or has been deactivated" |
| Missing id_token parameter | 422 | "id_token parameter required" |

---

## Security Considerations

1. **Token Validation:** `google_sign_in` gem validates JWT signature against Google's public keys (prevents forgery)
2. **Token Expiry:** Google ID tokens are short-lived (1 hour). Expired tokens are rejected automatically
3. **Email Matching:** Exact match (case-insensitive) to prevent bypass
4. **Status Check:** Only `active` users can login (leads, churned, archived are blocked)
5. **Secure Storage (Mobile):** Auth token stored in secure storage (`react-native-secure-storage` or encrypted `AsyncStorage`)
6. **No Token Refresh:** ID tokens are single-use. If expired, mobile must re-authenticate with Google
7. **Rate Limiting:** Recommended to add rate limiting to endpoint (e.g., `rack-attack` gem)

---

## Google Credentials Setup

1. Create Google Cloud Project at https://console.cloud.google.com
2. Enable Google Sign-In API
3. Create OAuth 2.0 credentials (type: iOS/Android as needed for mobile)
4. Get Client ID and Client Secret
5. Store in environment variables:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET` (optional for token validation, not always needed)
6. Configure in Rails (via `google_sign_in` gem initialization)

---

## Testing Strategy

### Unit Tests
- Mock Google token validation (valid/invalid/expired tokens)
- Test user lookup (exists + active, exists + inactive, doesn't exist)
- Test error response messages and HTTP statuses
- Test email extraction from token

### Integration Tests
- Full flow: valid token → find user → return auth_token
- Verify returned `auth_token` works for subsequent API calls (e.g., GET /sync)
- Test all error paths (invalid token, user not found, user inactive)
- Test that email matching is case-insensitive but exact

### Manual Testing (Mobile)
- Test with real Google Sign-In UI on iOS/Android
- Test with different user account states (lead, active, churned, archived)
- Test token expiry (wait 1+ hour, try to use old token)
- Test email mismatch scenario
- Test fallback to email/password login

---

## Out of Scope

- Linking Google account to existing email/password account (future enhancement)
- Social sign-up (creating new users via Google on mobile) — only existing, paid users can login
- Custom claims or scopes beyond email
- Two-factor authentication with Google
- Google Sign-In on web admin area (clients only)

---

## Success Criteria

- ✅ Mobile app can authenticate with Google and receive auth_token
- ✅ Returned token works for all existing API calls
- ✅ Unactivated/paid users are blocked from login
- ✅ Token validation rejects invalid/expired tokens
- ✅ Email/password fallback still works
- ✅ Error messages are clear and actionable
- ✅ No existing functionality is broken

---

## Implementation Order

1. Add `google_sign_in` gem to Gemfile
2. Create users table migration (add `google_uid`, `provider` columns)
3. Update User model (add `:omniauthable` to Devise)
4. Create `Api::V1::AuthController` with `#google` action
5. Add route: `POST /api/v1/auth/google`
6. Configure Google credentials (environment variables)
7. Write unit + integration tests
8. Test on React Native with real Google Sign-In
9. Update mobile app to use new endpoint
10. Update API docs

---

## Rollback Plan

If issues occur:
1. Remove Google Sign-In option from mobile app UI (keep email/password)
2. Endpoint remains in code but unused
3. Revert Devise changes if needed
4. Users fall back to email/password login
5. No data loss (Google tokens are never persisted)

