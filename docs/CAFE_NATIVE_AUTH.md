# Mood Changing Cafe — native app sign-in (SSO)

The Rejoice Greatly app embeds the cafe at `https://moodchangingcafe.vercel.app` in a WebView. When the user is signed in to the **same Firebase project** (`moodchangingcafe`), the app:

1. Calls `POST /auth/custom-token` on the church backend with the user's Firebase ID token.
2. Injects the returned **custom token** into the cafe page via JavaScript.
3. Sets `localStorage.rejoice_native_custom_token` and fires `rejoice-native-auth`.

## Required change in the cafe web app

Add this once where Firebase Auth is initialized (e.g. `layout.tsx`, `_app.tsx`, or auth provider):

```typescript
import { getAuth, signInWithCustomToken, onAuthStateChanged } from 'firebase/auth';

async function applyNativeAppSignIn() {
  const token = localStorage.getItem('rejoice_native_custom_token');
  if (!token) return;

  const auth = getAuth();
  try {
    await signInWithCustomToken(auth, token);
    localStorage.removeItem('rejoice_native_custom_token');
    localStorage.removeItem('rejoice_native_auth_pending');
  } catch (e) {
    console.warn('Native app SSO failed', e);
  }
}

// Run on load and when the native app injects a token
if (typeof window !== 'undefined') {
  applyNativeAppSignIn();
  window.addEventListener('rejoice-native-auth', () => applyNativeAppSignIn());
}
```

If the cafe site uses the **Firebase compat** SDK (`firebase.auth()`), the mobile app also attempts `firebase.auth().signInWithCustomToken(token)` automatically.

## Backend

- `POST /auth/custom-token`  
- Body: `{ "idToken": "<firebase id token>" }`  
- Response: `{ "customToken": "...", "firebaseUid": "..." }`

## Env (optional)

In the mobile app `.env`:

```
CAFE_WEB_URL=https://moodchangingcafe.vercel.app
```
