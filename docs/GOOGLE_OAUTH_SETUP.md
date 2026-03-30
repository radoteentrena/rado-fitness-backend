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
