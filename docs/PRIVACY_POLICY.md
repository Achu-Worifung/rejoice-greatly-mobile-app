# Privacy Policy

**Rejoice Greatly** · Last updated: July 24, 2026

> Church-specific values are read from the app's `.env` (`APP_NAME`,
> `LEGAL_ENTITY_NAME`, `PRIVACY_CONTACT_EMAIL`, `MAILING_ADDRESS`,
> `GOVERNING_STATE`, `LEGAL_EFFECTIVE_DATE`). This document is the canonical copy;
> the in-app version lives in `lib/pages/privacy_page.dart` and must be kept in
> sync. Good-faith draft grounded in how the app actually works — not legal
> advice. Have counsel review before release, especially Sections 4, 5, and 6.
>
> **Note for counsel:** the governing state is Arizona, which has no dedicated
> biometric privacy act. Section 4 therefore states our own commitments rather
> than citing a statute. If the congregation includes residents of states that do
> have one (Illinois' BIPA, Texas, Washington), those laws may still reach us and
> Section 4 should be revisited — BIPA in particular carries a private right of
> action and a written-release requirement at the moment of collection.

## 1. Introduction

Welcome to **Rejoice Greatly** (the "App," "we," "our," or "us"), operated by
**Rejoice Greatly Church, Inc.**

Your privacy is important to us. This Privacy Policy explains what information we
collect, how we use it, how we protect it, how long we keep it, and the choices
you have. It is written for members in the United States.

Because the App can use facial recognition for attendance, please read **Section 4
(Facial Recognition & Biometric Data)** closely — it is the most important part.
By using the App, you acknowledge that you have read and understood this Privacy
Policy.

**The short version:** facial recognition is one of three ways to check in, it is
offered only to members 18 and older, it is entirely optional, and **if you never
enroll, we never create a face template for you.**

## 2. Information We Collect

**Account information.** When you create an account, we may collect:

- Name
- Email address
- Username / display name
- Your date of birth
- Your sign-in method (email/password, Google, or Apple)

We ask for your date of birth for one purpose: to determine whether the facial
scan is offered to you at all. Members under 18 skip it.

Sign-in is handled through **Google Firebase Authentication**. If you use email
and password, your password is created, managed, and protected by Firebase using
industry-standard cryptographic hashing; we never receive or store your password
in plain text.

**Profile information.** You may choose to provide a profile photo, a display
name, and other profile details. **Your profile photo is separate from any facial
verification records** — a profile photo is only for display, and is never used
for recognition.

**Facial verification data (only if you enroll).** If you are 18 or older and
choose to enroll in facial recognition, we collect a series of facial photographs
during enrollment, captured on your own device while you look forward, turn your
head, and change viewing angles. From these we derive a **face embedding** — a
mathematical representation of your face — used solely to verify your identity and
record your attendance (see Section 4).

We do not collect facial verification data from members under 18, or from anyone
who does not enroll.

**NFC check-in.** You may check in by tapping your phone on the NFC tag at the
entrance. When you do, we collect the **tag's identifier** and the time, and
record that your signed-in account was present. NFC check-in involves no
biometrics and reads nothing off your person.

**Attendance & activity.** We collect records of when you were recognized or
checked in present, your attendance and absence counts, your current and longest
streaks, saved sermons, and your interactions with events and reminders.

**Device & technical information.** We may automatically collect device model and
operating system, application version, crash reports and diagnostics, security
logs, and a push-notification identifier for your device (via OneSignal). This
helps us keep the App secure, reliable, and working.

## 3. How We Use Your Information

We use collected information to:

- Create and manage your account
- Verify your identity and record your attendance
- Secure access to the App and detect fraud or unauthorized access
- Improve authentication and recognition accuracy
- Maintain system security and reliability
- Send push notifications and email reminders you have allowed
- Provide sermons, events, the weekly verse, the café, and other features
- Provide support and comply with our legal obligations

We do **not** use facial verification photographs or face embeddings for
advertising, marketing, or user profiling.

## 4. Facial Recognition & Biometric Data

This section is our biometric-privacy notice. "Biometric data" here means the
facial photographs captured during enrollment and the face embeddings derived from
them.

Arizona does not currently have a dedicated biometric privacy statute of the kind
some states have enacted. **We hold ourselves to those standards anyway.** We treat
your facial data as sensitive personal information — as Arizona's data-breach
notification law does — and we follow the practices those stricter laws require:
tell you before we collect it, collect it only with your consent, use it for one
stated purpose, never sell it, and destroy it once that purpose ends.

**Who this applies to.** Only members **18 and older who choose to enroll**.
Enrollment is voluntary, it is not required to use the App, and it is not required
to attend anything.

**Purpose.** Facial verification data is processed **exclusively** to verify your
identity and record your attendance at church services. We do not use it for any
other purpose.

**Your consent.** We collect facial data only after you give informed consent.
Before enrollment you are told that facial data is being collected and why, and by
agreeing and completing the capture step you authorize **Rejoice Greatly Church,
Inc.** to collect, store, and use it as described here.

**How enrollment actually works:**

- **Capture** — At sign-up, the App uses the **front camera of your own phone** to
  take several photos of your face from a few angles. On-device face detection
  (Google ML Kit) runs only to guide the capture; it stays on your device and is
  not sent anywhere.
- **Encryption** — Each photo is encrypted on your device (AES-256-GCM) before it
  is uploaded, and travels over an encrypted connection to a temporary, private
  staging area. A leaked link would reveal only ciphertext.
- **Validation** — We decrypt the photo only in memory to confirm it contains a
  single, clear face, then save a private image and create the face embedding used
  for recognition. The temporary encrypted upload is deleted immediately
  afterward; abandoned uploads are automatically swept and deleted.
- **Recognition** — The on-premise recognition system loads enrollment images into
  memory only, converts them into face embeddings, and keeps those embeddings in a
  local index. It does **not** save headshots to disk. On service days it matches
  faces seen by on-site cameras against that index and marks recognized members
  present.

**If you have not enrolled, you have no face template.** The attendance cameras
match only against the embeddings of members who opted in. Members under 18,
members who use NFC or a greeter instead, visitors, guests, and anyone who does
not use the App are **not identified, not enrolled, and have no biometric record
created — ever.** A face the system does not have an embedding for is simply not a
match, and nothing about it is stored.

**Who can see it.** Your facial data is not visible to other members. Stored images
are kept in private storage that is never publicly accessible. Only authorized
administrators and the systems that run enrollment and recognition can access
biometric data and attendance records, and only to operate attendance.

**We do not sell it.** We do not sell, lease, trade, or otherwise profit from your
biometric data.

**Retention & destruction.** We keep your biometric data only as long as it is
needed for the purpose described above — recognizing you at church. **When that
purpose ends, it is destroyed:** if you delete your account or withdraw your
consent, we permanently delete your enrollment images and face embeddings.

You never have to wait for a clock to run out. Ask us and we delete it.

## 5. Cameras, Photography, and Recording on Our Premises

This section describes what happens on the property, separate from the App.

**Security video.** For the safety and security of our congregation and
facilities, the property is monitored by video surveillance **24 hours a day, 7
days a week.**

**Ministry photography and recording.** Worship services, church events, and
activities **may be photographed and/or recorded** for ministry, promotional,
livestream, website, and social media purposes. By entering the premises, you
acknowledge that your image, voice, or likeness may be captured.

**Your choice.** If you prefer not to appear in photographs, videos, livestreams,
or social media content, **please notify a church leader or a member of the media
team** so that reasonable accommodations can be made.

**These are not facial recognition.** Security footage and ministry photography are
not run through the recognition system, are not used to create or improve face
embeddings, and are not linked to your App account or attendance record. Being
filmed at a service does not enroll you in anything.

## 6. Children and Members Under 18

The App itself is open to the whole congregation, including members under 18 —
they can follow sermons, events, the weekly verse, and their attendance like
anyone else.

**We do not collect biometric data from anyone under 18.** When the date of birth
given at sign-up is under 18, the App skips facial enrollment entirely: no facial
photographs are captured, no embedding is created, and the attendance cameras have
nothing to match against. Younger members check in by NFC tap or with a greeter.

For children under 13, a parent or guardian should create and supervise the
account, and by doing so consents to the collection of that account information as
described in Section 2. If you are a parent or guardian and would like to review or
delete your child's information, contact us using Section 13 and we will do so.

## 7. Data Security

We employ multiple layers of security designed to protect your information,
including:

- Encryption in transit using secure communication protocols
- Client-side encryption of enrollment photos before they leave your device
- Encryption at rest for stored data, with protected encryption keys
- Private (non-public) storage for images
- Access controls limiting authorized personnel and systems
- Authentication and authorization safeguards
- Security monitoring and logging, and regular security updates

We store and protect biometric data using at least the same care we use for other
confidential information. While we strive to protect your information using
commercially reasonable measures, no method of electronic storage or transmission
is completely secure.

## 8. Data Sharing

We do **not** sell your personal information or facial verification photographs.
We share information only:

- With cloud infrastructure and service providers that help us operate the App,
  under contracts that restrict their use of it — including **Google Firebase**
  (authentication), **Google / Apple** (the "Sign in with" option you choose),
  **Microsoft Azure** (encrypted image storage and key protection), **OneSignal**
  (push and email reminders), and the **Mood Changing Café** (hosted on Vercel,
  the connected café opened from the App)
- When required by law, or in response to a valid legal request
- To protect members, investigate fraud, or enforce our agreements

On-site attendance cameras and the recognition software run on equipment operated
by the Church. We do not share your biometric data with any party for that party's
own purposes.

## 9. Data Retention

We retain your information only as long as necessary to provide our services,
maintain account and attendance security, meet legal obligations, and resolve
disputes. Biometric data is retained as described in Section 4. If you delete
your account, we will delete or anonymize your personal information within a
reasonable period, unless retention is required by law.

## 10. Your Rights and Choices

Depending on where you live, you may have the right to:

- Access your information, and obtain a copy of it
- Correct inaccurate information (including a wrong attendance record)
- Delete your account
- Request deletion of your facial verification photographs and embeddings
- Withdraw consent for facial recognition at any time
- Check in by NFC or with a greeter instead of facial recognition
- Not be discriminated against for exercising any of these rights

**How to exercise them.** Use *My Profile → Account → Delete my account* to send
your request to the church team, or contact us using Section 13. Deletion is
handled personally by the team rather than by a self-service button, precisely
because facial data is involved. We will verify your request before acting on it
and respond within the timeframe the law requires.

Withdrawing consent for facial recognition disables face check-in for you and
deletes your embeddings; every other way of checking in stays open, with no
penalty and no loss of church privileges.

## 11. International Transfers

Your information may be processed or stored in countries other than your own.
Where required by applicable law, we implement safeguards designed to protect
personal information during international transfers.

## 12. Changes to This Privacy Policy

We may update this Privacy Policy periodically. When we do, we will change the
"Last updated" date above and communicate material changes through the App or by
other appropriate means. For material changes to how we handle facial data, we
will notify you in the App and — where the law requires it — ask for your consent
again before the change affects you. Continued use of the App after changes become
effective constitutes acceptance of the revised Privacy Policy.

## 13. Contact Us

For any privacy question, or to access, correct, or delete your data (including
your facial data), contact us at:

- **Email:** [PRIVACY CONTACT EMAIL]
- **Mail:** [CHURCH MAILING ADDRESS]

---

*In plain terms: if you opt in, your face is used to check you in at church and
nothing else. If you don't, nothing about your face is ever stored. Enrollment
photos are encrypted on your phone, kept private, and deleted when you ask.*
