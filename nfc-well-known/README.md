# NFC deep-link association files (staging copy)

These two files enable **tap-to-launch NFC check-in** (see
`../docs/NFC_TAP_TO_LAUNCH_TODO.md`). They are staged **here in the mobile-app
repo** for convenience, but they must be **served from the admin website's
domain** (the Vercel-hosted `rejoice-greatly-admin` site) — that is the domain
that will be written onto the NFC tags.

## What to do with them

Copy the `.well-known/` folder from here into the admin site so the files are
served at the **domain root**:

- **Next.js / most static hosts:** copy to `public/.well-known/` in
  `rejoice-greatly-admin`. Vercel then serves them at
  `https://<your-domain>/.well-known/...`.
- **Other setups:** ensure they end up at exactly these URLs (root, not a
  subpath).

They must be reachable at:

```
https://<your-domain>/.well-known/apple-app-site-association
https://<your-domain>/.well-known/assetlinks.json
```

## Requirements (or verification silently fails)

- **HTTPS with a valid cert** (Vercel does this automatically).
- **No auth / no login wall / no password protection** on `/.well-known/*`.
  If the admin app gates routes, exclude `/.well-known/*`.
- **No redirects** on those paths.
- `apple-app-site-association` is served with **no file extension** and,
  ideally, `Content-Type: application/json`. On Vercel from `public/` this
  works as-is; if your host forces a content type, add a header rule.

## Placeholders you MUST replace before it works

### `apple-app-site-association`
- `TEAM_ID_PLACEHOLDER` → your **Apple Developer Team ID** (10 chars, e.g.
  `A1B2C3D4E5`). Find it in the Apple Developer portal → Membership, or as the
  prefix of your App ID. Result should read `A1B2C3D4E5.com.rejoicegreatly.app`.
- `paths` is scoped to `/checkin` and `/checkin/*` — matches the tag URL
  format `https://<domain>/checkin?tag=<tagId>`. Widen if you change the URL.

### `assetlinks.json`
- `package_name` is currently `com.example.church_app` — the app's **current**
  Android applicationId. ⚠️ This is still the default `com.example.*`; if you
  rename it before shipping, update this value to match.
- `SHA256_PLACEHOLDER_...` → the **SHA-256 fingerprint** of the signing cert.
  Get it with:
  ```
  keytool -list -v -keystore <your-release-keystore> -alias <alias>
  ```
  For local debug testing also add the debug keystore's fingerprint:
  ```
  keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android
  ```
  You can list **multiple** fingerprints in the array (debug + release, or the
  Play App Signing cert from the Play Console → Setup → App integrity).

## Verify after deploying

- iOS AASA (Apple's CDN cache):
  `https://app-site-association.cdn-apple.com/a/v1/<your-domain>`
- Android App Links:
  `https://developers.google.com/digital-asset-links/tools/generator`
  or
  `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://<your-domain>&relation=delegate_permission/common.handle_all_urls`
