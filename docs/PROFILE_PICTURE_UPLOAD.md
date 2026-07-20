# Profile picture upload — backend contract

The signup selfie is uploaded **directly to Azure Blob Storage** by the app,
using a short-lived SAS URL minted by the backend. The storage account key is
never shipped in the app.

Client: `lib/services/profile_picture_upload.dart`, called from
`lib/pages/complete_signup.dart`.

## Multi-angle enrolment (multiple mugs per member)

Signup captures **10–15 stills** as the member turns their head (ML Kit guides
the rotation and a new shot is taken each time the pose changes enough). Each
still runs the **full three-step flow below independently** — so one signup
issues 10–15 SAS grants and 10–15 commits. Every committed image becomes its own
recognition **mug** on the backend (a `face_image` row), giving the kiosk
several embeddings per person for pose/lighting robustness. The member's display
`imgURL` is set from the first shot that commits successfully; blurry frames that
fail face validation are skipped as long as at least one lands.

Because a single signup now issues many grants, the backend's per-account
`picture.upload.max-grants-per-hour` must clear 15 plus a retry or two (set to
40).

## Why three steps

The retired endpoint (`POST /auth/picture-upload`, multipart — now removed, and
it returns 404) let the backend validate the face from the request body. With a
direct-to-blob upload the backend never sees the bytes in flight, so validation
moves to a **commit** call after the blob lands.

```
1. POST /auth/picture-upload/sas      -> SAS URL + fresh AES-256-GCM key
2. PUT  <uploadUrl>                   -> ciphertext, app -> Azure directly
3. POST /auth/picture-upload/commit   -> decrypt, validate face, publish
```

## What is and isn't encrypted

The blob written in step 2 is a **staging artifact**, encrypted client-side.
A leaked SAS URL therefore yields ciphertext only.

The image the app later renders is **not** encrypted: `imgURL` is consumed by
plain `Image.network` / `NetworkImage` in `me_page.dart`,
`attendance_widget.dart` and `user_dashboard.dart`. Step 3 writes that servable
image to its final location and **deletes the staging blob**.

Face data is GDPR Art. 9 special-category data — the staging blob holds the raw
capture and should not outlive the commit.

---

## 1. `POST /auth/picture-upload/sas`

```jsonc
// request
{ "idToken": "<firebase id token>", "contentType": "image/jpeg" }
```

```jsonc
// response data
{
  "uploadUrl":   "https://<acct>.blob.core.windows.net/<container>/<blob>?<sas>",
  "blobName":    "staging/<uid>/<uuid>.bin",
  "uploadToken": "<opaque, single-use>",
  "key":         "<base64, exactly 32 bytes>",
  "iv":          "<base64, exactly 12 bytes>",
  "expiresAt":   "2026-07-19T12:34:56Z"
}
```

Requirements:

- **SAS lifetime 5–10 minutes**, permission **create+write only** — no read, no
  delete, no list. Scope it to the single blob, not the container.
- **`key` and `iv` MUST be freshly random per grant.** Reusing a
  (key, IV) pair under AES-GCM is catastrophic — it leaks the XOR of both
  plaintexts and enables tag forgery. Generate from a CSPRNG each call.
- Wrap `key` into Key Vault (or equivalent) keyed by `uploadToken` before
  returning. The app discards its copy immediately after encrypting; the
  backend must be able to recover it in step 3 without the app's help.
- `uploadToken` binds the grant to the caller's uid and to `blobName`. Step 3
  must NOT accept a caller-supplied blob path — that would let any member
  commit any blob.
- The client rejects a `key` or `iv` of the wrong length, so a misconfigured
  backend fails loudly rather than silently weakening the cipher.

## 2. `PUT <uploadUrl>`

Sent by the app directly to Azure:

```
x-ms-blob-type: BlockBlob
Content-Type:   application/octet-stream

<AES-256-GCM ciphertext> || <16-byte GCM tag>
```

Layout is `ciphertext || tag` — the tag is the **trailing 16 bytes**, so no
separate field is needed. No AAD is used. Plaintext is the raw JPEG.

The app retries once with a fresh grant if the SAS expired before use, and
surfaces Azure's 403 as an expiry rather than as an auth failure.

## 3. `POST /auth/picture-upload/commit`

```jsonc
// request
{ "idToken": "<firebase id token>", "uploadToken": "<from step 1>" }
```

```jsonc
// response data
{ "imgURL": "https://.../profile/<uid>.jpg" }
```

Backend work, in order:

1. Resolve `uploadToken` → uid + `blobName`; reject if spent, expired, or the
   uid doesn't match the `idToken`.
2. Download the staging blob, split the trailing 16 bytes as the GCM tag,
   unwrap the key from Key Vault, decrypt and verify. **A failed tag check must
   abort** — it means the ciphertext was tampered with.
3. Run face validation on the decrypted JPEG.
4. On success: write the servable image, set `imgURL` + `signupComplete` on the
   account, delete the staging blob, mark the token spent.
5. On failure: delete the staging blob, mark the token spent, return the error
   below.

### Error codes

Returned as `errorCode` in the standard `ApiResponse` envelope (see
`lib/services/api_envelope.dart`), **not** as bare HTTP statuses:

| `errorCode`            | Status | Meaning                              |
|------------------------|--------|--------------------------------------|
| `FACE_NOT_CLEAR`       | 422    | Undecodable or unreadable image      |
| `MULTIPLE_FACES`       | 422    | More than one person in frame        |
| `NO_FACE_DETECTED`     | 422    | No person found                      |
| `UPLOAD_TOKEN_EXPIRED` | 410    | Grant spent, expired, or blob absent |
| `UPLOAD_TOO_LARGE`     | 413    | Blob over the server's size cap      |
| `NOT_UPLOAD_OWNER`     | 403    | Token belongs to another account     |
| `TOO_MANY_UPLOADS`     | 429    | Past the per-account grant limit     |
| `DETECTION_FAILED`     | 500    | Detector broke; grant stays reusable |

The previous endpoint overloaded `400` / `401` / `403` for the three face
cases. That must not carry over: `commit` can genuinely return `401` on an
expired id token, and the app has to tell a rejected *photo* (retake) apart
from a failed *session* (re-auth). The client keys off `errorCode` and treats a
bare 401/403 as a session failure.

## Operational notes

- Staging container: set a **lifecycle rule deleting blobs after ~1 hour** so
  abandoned uploads (app killed between steps 2 and 3) don't accumulate raw
  captures. The commit path deletes them, but only when it runs.
- Rate-limit step 1 per uid. Each call mints a SAS; unbounded issuance is the
  obvious abuse path.
- The staging container should have **no public access** and no anonymous read.

## How the published image stays private

The container blocks public access, so bare blob URLs are unreadable. The
database stores the bare URL and every API response signs it with a 7-day
read-only SAS (`BlobSasService.signUrl`) on the way out — which is why
`Image.network(imgURL)` works at all. The app refreshes those URLs on each
sync, so the TTL only has to outlive a cached session.

Nothing extra is needed here: the *published* image is protected by the read
SAS, and the *staging* blob by client-side encryption.
