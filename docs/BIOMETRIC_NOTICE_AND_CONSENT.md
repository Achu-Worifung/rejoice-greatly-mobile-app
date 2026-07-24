# Biometric Information Notice & Consent

**Rejoice Greatly** · Effective: July 24, 2026

> Church-specific values are read from the app's `.env` (`APP_NAME`,
> `LEGAL_ENTITY_NAME`, `PRIVACY_CONTACT_EMAIL`, `LEGAL_EFFECTIVE_DATE`). This
> document is the canonical copy; the in-app version lives in
> `lib/pages/biometric_notice_page.dart` and the consent gate that references it
> is in `lib/pages/user_prep.dart`. Keep all three in sync.
>
> Good-faith draft grounded in how the app actually works — not legal advice.
> **Note for counsel:** this is the written notice-and-release shown at the moment
> of collection. The governing state is Arizona, which has no dedicated biometric
> privacy act, so this notice reflects voluntary standards. If members reside in
> states that do have one (Illinois' BIPA in particular), the consent record and
> its storage should be reviewed against that law's requirements.

## Biometric Information Notice

This Notice explains how **Rejoice Greatly Church, Inc.** ("we," "our," or "us")
collects, uses, stores, protects, and deletes facial verification information when
you choose to enroll in face check-in for the **Rejoice Greatly** app.

Please read it before enabling facial recognition.

**What this is used for.** Your face is used for one thing: **marking you present
at church.** It is not how you sign in — signing in uses your email and password,
or Sign in with Google or Apple, and that does not change if you enroll. Your face
is never a password.

## 1. Enrollment Is Voluntary

Facial recognition is optional, and it is offered only to members **18 and older**.

You can check in two other ways that involve no facial data at all:

- **Tap the NFC tag** at the entrance with your phone.
- **Check in with a person** at the information desk or with a greeter.

Declining facial recognition does not limit the rest of the app, and it carries no
penalty, no restriction of entry, and no loss of church privileges. Using the app
is not a requirement to attend anything.

**If you do not enroll, no face template is ever created for you.** Members under
18, members who use NFC or a greeter, visitors, guests, and people who do not use
the app are not identified by the attendance cameras and have no biometric record.

## 2. Eligibility for Facial Recognition

Facial recognition is an optional authentication feature that is available only to
eligible users who attend participating church locations where the feature has been
deployed.

To protect user privacy and comply with applicable laws, facial recognition
enrollment is **not** available to:

- Individuals under 18 years of age.
- Users who do not attend a participating church location.
- Users located in jurisdictions where we have chosen not to offer facial
  recognition due to legal, regulatory, or operational considerations.
- Users whose accounts are not authorized for facial recognition by the
  participating church.

Users who are not eligible for facial recognition will authenticate using another
supported method, such as an NFC security tag or other authentication methods made
available by the App.

We do not knowingly collect facial verification photographs, biometric templates,
or other facial recognition enrollment data from users who are not eligible for
facial recognition. If such information is inadvertently submitted, we will take
reasonable steps to delete it in accordance with our data retention policies and
applicable law.

At this time, facial recognition is intended solely for use on the grounds of
participating church locations during authorized church activities. The feature is
not designed or intended for general-purpose identity verification outside of those
participating church locations.

## 3. Information We Collect

If you voluntarily enroll, we collect:

- **A series of facial photographs captured during enrollment**, taken with the
  front camera of your own phone. The app asks you to look forward and turn your
  head through a few angles — this improves accuracy and makes it harder to fool
  the system with a photograph of someone else.
- **A face embedding** derived from those photographs: a mathematical
  representation of your face, which is what the system actually matches against.
- **Technical details needed to record attendance**, such as the date and time you
  were recognized, and basic device information from the enrollment session.

**About the cameras at church.** On service days, cameras operated by the Church
compare the faces they see against the embeddings of enrolled members and mark
recognized members present. The recognition system holds those embeddings in
memory and **does not save headshots from the cameras to disk.**

Members under 18 are not asked to enroll and are not asked for facial photographs.

## 4. Why We Collect It

Your facial verification information is used **solely** to:

- Recognize you at church and record your attendance;
- Keep your attendance record accurate; and
- Detect and prevent someone logging attendance as you.

It is **not** used for advertising, marketing, profiling, unrelated analytics, or
any purpose beyond attendance. It is not used to unlock your account, and it is
not shared with other members.

## 5. How Your Photographs Are Handled

- **Encrypted on your phone.** Each enrollment photo is encrypted on your device
  (AES-256-GCM) before it is uploaded, and travels over an encrypted connection to
  a temporary, private staging area. Anyone who intercepted the link would see
  only ciphertext.
- **Decrypted only in memory.** We decrypt each photo in memory just long enough
  to confirm it contains a single, clear face, then save a private image and
  create your face embedding.
- **Staging cleaned up immediately.** The temporary encrypted upload is deleted
  right after; uploads that are abandoned partway are automatically swept and
  deleted.
- **Kept private.** Stored images live in private storage that is never publicly
  accessible.

## 6. Storage and Protection

We protect facial verification information with:

- Encryption in transit and at rest, with protected encryption keys
- Client-side encryption before photos leave your device
- Private, non-public image storage
- Access controls limiting authorized personnel and systems
- Authentication and authorization safeguards
- Security monitoring, logging, and regular security updates

Only authorized administrators and the systems that run enrollment and recognition
can reach biometric data and attendance records, and only to operate attendance.
No security system can guarantee absolute protection, but we maintain commercially
reasonable administrative, technical, and organizational safeguards.

## 7. Alternatives, and Changing Your Mind

You may stop using face check-in at any time and switch to tapping the NFC tag at
the entrance or checking in with a greeter. Neither requires you to give up
anything else in the app, and neither involves biometric data.

## 8. Retention and Deletion

We keep facial verification information only as long as it is needed to recognize
you at church.

**When that purpose ends, it is destroyed.** If you withdraw your consent or delete
your account, your enrollment images and face embeddings are permanently deleted,
and the attendance cameras no longer match you. You do not have to wait for any
retention period to run out — ask us and we delete it, unless a longer period is
required by law.

## 9. Sharing

We do **not** sell, lease, trade, or otherwise profit from your facial verification
information.

We disclose it only:

- To service providers acting on our behalf under contractual confidentiality
  obligations;
- To comply with applicable law or valid legal process; or
- To investigate fraud or protect the safety, rights, or security of our members.

The attendance cameras and recognition software run on equipment operated by the
Church. We do not share your biometric data with any party for that party's own
purposes.

## 10. Your Choices

You have the right to:

- Decline facial enrollment entirely;
- Check in by NFC tap or with a greeter instead;
- Withdraw your consent at any time;
- Request deletion of your facial verification photographs and embeddings;
- Ask us to correct an attendance record that is wrong.

To withdraw consent or request deletion, use **My Profile → Account → Delete my
account**, which sends your request to the church team, or contact us below.
Withdrawing consent disables face check-in for you; every other way of checking in
stays open.

## 11. Consent

By selecting **"I Agree"** and continuing with facial enrollment, you acknowledge
that:

- You have read and understand this Biometric Information Notice.
- You voluntarily consent to **Rejoice Greatly Church, Inc.** collecting,
  processing, storing, and using your facial verification information as described
  here, and you authorize the creation of a face embedding from your enrollment
  photographs.
- You understand it is used **solely to recognize you at church and record your
  attendance**, and not to sign you in or unlock your account.
- You understand enrollment is optional, that NFC and in-person check-in are
  available to you instead, and that declining carries no penalty.
- You understand you may withdraw this consent at any time and have your facial
  data deleted.
- You confirm that **you are at least 18 years of age.**
- You confirm that **you meet the eligibility requirements in Section 2** — you
  attend a participating church location, you are enrolling for attendance at that
  location, and you are not located in a jurisdiction where we do not offer this
  feature.

If you do not agree, or you are not eligible, do not enable facial recognition. Tap
the NFC tag at the entrance or check in with a greeter instead — you are just as
welcome either way.

## Contact

Questions about this Notice, or want to exercise any of the choices above?

- **Email:** [PRIVACY CONTACT EMAIL]
- **Mail:** [CHURCH MAILING ADDRESS]

---

*This Notice sits alongside the Rejoice Greatly [Privacy Policy](PRIVACY_POLICY.md)
and [Terms of Use](TERMS_OF_USE.md). Where they describe the same thing, they are
meant to agree — if they ever do not, tell us and we will fix it.*
