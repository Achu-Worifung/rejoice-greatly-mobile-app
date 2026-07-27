# TODO: NFC tap-to-launch check-in

Status: **Not started** — planning captured, implementation pending.

## Why this exists

Members reported that tapping a provisioned tag shows Android's generic
**"New tag scanned"** popup instead of checking them in — even though the tag
is written correctly (`entrance-1304`) and registered in the admin console.

That popup is **Android's OS**, not our app. The app currently reads tags
**only through a foreground reader session** started by the "Check in with NFC"
button (`lib/services/nfc_checkin_service.dart` → `NfcManager.startSession`).
There is **no NFC intent filter** in `AndroidManifest.xml`, so a tap made
outside the app is handled by the OS, not us. Registering the tag in admin has
no effect on this — the app never receives the tag.

### Works today (no code change)
Open app → tap **"Check in with NFC"** → *then* present the tag. Tapping the
tag before opening the app will always show the OS popup.

### Goal of this TODO
Make tapping the tag **launch the app and check the member in automatically**,
on both Android and iOS.

## Decided approach: URL record + Universal Links / App Links

Plain **Text** records (what our tags hold now) **cannot** trigger auto-launch
on either platform — the OS can only route on a **URL** or **MIME** record.
Chosen format: a **URL record** so it works cross-platform and degrades
gracefully (uninstalled users land on a web page).

Tag payload becomes, e.g.:
```
https://<vercel-domain>/checkin?tag=entrance-1304
```

Hosting: the admin site's **Vercel domain** will host the association files.
Confirmed workable, with caveats below.

## App identifiers (from the repo)

- iOS bundle id: `com.rejoicegreatly.app`
- Android applicationId: `com.example.church_app`  ⚠️ still the default
  `com.example.*` — cannot be published to Play Store; rename before tying
  verified App Links + physical tags to it.

## Values still needed (fill these in)

- [ ] Exact Vercel domain (e.g. `rejoice-admin.vercel.app`)
- [ ] Apple Developer **Team ID** (10 chars, e.g. `A1B2C3D4E5`) — for AASA
- [ ] Android signing key **SHA-256** fingerprint
      (`keytool -list -v -keystore <keystore>`) — for `assetlinks.json`
      (include both debug and release fingerprints)

## Implementation checklist

### App (Flutter / native)
- [ ] Android: add `NDEF_DISCOVERED` intent filter with `android:autoVerify="true"`
      on the Vercel host in `android/app/src/main/AndroidManifest.xml`.
- [ ] iOS: add **Associated Domains** entitlement
      (`applinks:<vercel-domain>`) in `ios/Runner/Runner.entitlements`.
- [ ] Handle the incoming deep link on cold start + warm resume; extract the
      `?tag=` value and run the existing check-in POST.
- [ ] Change admin write sheet (`lib/widgets/nfc_write_tag_sheet.dart` →
      `NfcCheckinService.writeTag`) to write a **URL record**
      (`NdefRecord.createUri`) instead of `NdefRecord.createText`.
- [ ] Update the reader (`_extractTagId` / `_decodeTextRecord`) to parse
      `?tag=` from a URL record **and still read legacy Text tags** during the
      transition, so nothing breaks mid-swap.

### Web (Vercel admin site — separate repo)
- [ ] Host `https://<vercel-domain>/.well-known/apple-app-site-association`
      (iOS) — JSON, `appID = <TeamID>.com.rejoicegreatly.app`.
- [ ] Host `https://<vercel-domain>/.well-known/assetlinks.json` (Android) —
      package `com.example.church_app` (or renamed) + SHA-256 fingerprint(s).
- [ ] Ensure `/.well-known/*` is **publicly reachable**: no login wall, no
      Vercel password protection, no redirect, HTTPS. If the admin site gates
      routes, exclude `/.well-known/*`.
- [ ] Add a `/checkin` landing page for users **without** the app installed
      (e.g. "Get the Rejoice Greatly app").

## Caveats / risks

- **Login still required.** Check-in POSTs a Firebase id token
  (`ChurchApi.nfcCheckin`). An auto-launched but signed-out member can't be
  silently checked in — they land on login first. The tag cannot bypass auth.
- **Tag URL is permanent-ish.** The domain is physically written onto tags.
  A default `*.vercel.app` domain is fine for testing, but **attach a stable
  custom domain before mass-provisioning tags** — otherwise moving/renaming
  the Vercel project breaks every tag.
- **Re-write existing tags.** Tags written as Text records (the current
  `entrance-1304` tag) must be re-written in the new URL format once the write
  sheet is updated. The transition-safe reader keeps old tags working until
  then.
- **iOS background NFC** launches the app *with the URL* — it does not hand
  over a live tag session. Check-in is driven by the URL's `?tag=` param.
