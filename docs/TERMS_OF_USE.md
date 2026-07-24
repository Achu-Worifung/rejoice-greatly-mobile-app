# Terms of Use

**Rejoice Greatly** · Last updated: July 24, 2026

> Church-specific values are read from the app's `.env` (`APP_NAME`,
> `LEGAL_ENTITY_NAME`, `SUPPORT_CONTACT_EMAIL`, `MAILING_ADDRESS`,
> `GOVERNING_STATE`, `LEGAL_EFFECTIVE_DATE`). This document is the canonical copy;
> the in-app version lives in `lib/pages/terms_page.dart` and must be kept in sync.
> Good-faith draft grounded in how the app actually works — not legal advice.
> Have counsel review before release, especially Sections 1, 5, 6, 12, 13, and 15.
>
> **Note for counsel:** the governing state is Arizona (Section 15), which has no
> dedicated biometric privacy act. The biometric commitments in Section 5 and in
> the Privacy Policy are voluntary standards, not statutory minimums. See the
> corresponding note in `PRIVACY_POLICY.md` about members who reside in states
> that do have such a law.

## Introduction

Welcome to **Rejoice Greatly** (the "App"). These Terms of Use ("Terms") are an
agreement between you and **Rejoice Greatly Church, Inc.** ("we," "us," or "the
Church") and govern your use of the App and the features within it.

Please read these Terms together with our Privacy Policy, which explains how we
handle your information — including the facial (biometric) data used to record
attendance. By creating an account or using the App, you agree to both.

## 1. Who Can Use the App

The App is for the whole congregation. **There is no minimum age to have an
account** — members of every age are welcome to use it to follow sermons, events,
the weekly verse, and their attendance.

Age matters in exactly one place: **facial recognition is offered only to members
18 and older.** During sign-up we ask for your date of birth for this reason
alone. Members under 18 skip the facial scan entirely and go straight into the
App (see Section 6).

You confirm that:

- the information you give us at sign-up, including your date of birth, is true
  and belongs to you;
- you will keep your sign-in credentials confidential and are responsible for
  activity under your account; and
- if you are under 18, a parent or guardian is aware of and consents to your use
  of the App. For children under 13, a parent or guardian should create and
  supervise the account.

## 2. The App Is Free

The App is provided to the congregation free of charge. There is no subscription,
membership fee, or payment of any kind required to use it or any of its check-in
methods. (The Mood Changing Café, described in Section 9, may sell items under its
own terms.)

## 3. Your Account and Sign-In

You can create an account with your email and a password, or by using Sign in with
Google or Sign in with Apple. Sign-in is handled through Google Firebase
Authentication. You are responsible for maintaining the security of the email
account or provider you use to sign in.

## 4. Checking In — and Your Choice of How

Recording attendance is a core purpose of the App. **How you check in is entirely
your choice**, and every option below carries the same weight:

- **Facial recognition** (members 18 and older who opt in). You enroll once from
  your own phone; on service days, cameras operated by the Church at its
  premises match enrolled members and mark them present. See Section 5.
- **NFC tap.** Tap your phone on the NFC tag at the entrance and the App marks you
  present. No facial data is involved. The App reads the tag's identifier — it
  does not read anything off you.
- **Manually, with a person.** Check in at the information desk or with a greeter.

**Participation in automated attendance is 100% voluntary.** Using the App is not
a requirement to attend worship services or events, or to be part of our church
family, and choosing a manual alternative results in **no penalty, no restriction
of entry, and no loss of church privileges** of any kind.

**Please understand:** recognition is not perfect. Lighting, pose, camera position,
headwear, eyewear, appearance changes, and NFC read errors can cause a missed or
incorrect match. Attendance records are a convenience and may contain errors —
contact the Church and we will correct your record.

## 5. Consent to Facial (Biometric) Processing

This section applies **only if you are 18 or older and choose to enroll**. If you
do not enroll, nothing in this section applies to you.

By completing the facial enrollment step, you give explicit, informed consent for
the Church to:

- capture several photographs of your face **using the front camera of your own
  device**, at sign-up, while you look forward and turn your head through a few
  angles;
- convert those photographs into an encrypted mathematical representation (a
  "face embedding") stored for automated attendance; and
- use cameras positioned at Church entrances on service days to match your face
  against that stored embedding and mark you present.

**We only recognize people who have enrolled.** The on-site attendance cameras
compare what they see against the embeddings of members who have opted in.
**If you have not enrolled — because you use NFC, check in with a greeter, are
under 18, or do not use the App at all — no face template is ever created for
you, and the attendance system does not attempt to identify you.** Visitors and
guests are never enrolled.

Your consent is not a condition of anything else. You may withdraw it at any time
under Section 11, and Section 4's alternatives remain fully open to you.

## 6. Members Under 18

Members under 18 are welcome in the App. When the date of birth entered at
sign-up is under 18, the App **does not offer facial enrollment, does not capture
facial photographs, and does not create biometric data** — that step is skipped
and the member goes straight to the dashboard. Younger members check in by NFC tap
or with a greeter.

If you believe a minor's account has facial data associated with it, contact us
using Section 16 and we will delete it.

## 7. Cameras, Photography, and Recording on Our Premises

Separate from the App, and applying to everyone on the property:

For the safety and security of our congregation and facilities, **this property is
monitored by video surveillance 24 hours a day, 7 days a week.**

Worship services, church events, and activities **may also be photographed and/or
recorded** for ministry, promotional, livestream, website, and social media
purposes. By entering the premises, you acknowledge that your image, voice, or
likeness may be captured in photographs or recordings.

If you prefer not to appear in photographs, videos, livestreams, or social media
content, **please notify a church leader or a member of the media team** so that
reasonable accommodations can be made.

Security video and ministry photography are not the same as the App's attendance
recognition, are not used to build face embeddings, and are not connected to your
App account.

## 8. Sermons, Events, Reminders, and Content

The App lets you play sermons and audio, browse and get reminders about events,
view a weekly verse, track attendance streaks, and access community features.
Content in the App (sermons, media, event details, verses, and text) is provided
for your personal, non-commercial use and remains the property of the Church or
its licensors.

With your permission, the App sends push notifications and email reminders. You
can turn notifications off in your device settings at any time.

## 9. The Mood Changing Café

The App includes a café/community area that opens the Mood Changing Café, a
connected web experience. When you are signed in, the App can pass your sign-in
securely into the café so you do not have to log in again. The café is a separate
service with its own features (such as ordering and order history) and may have
its own terms, which apply in addition to these.

## 10. Acceptable Use

You agree not to:

- enroll, or attempt to have recognized, **anyone's face but your own** — you may
  only enroll your own face, or the face of a legal dependent for whom you have
  lawful authority to give consent;
- bypass, spoof, trick, or disrupt the recognition system — for example, holding
  up a photograph of another person, or tapping the entrance tag on someone
  else's behalf, to log attendance;
- impersonate another person, or access accounts, attendance records, or Church
  systems that are not yours, including admin or moderation tools;
- interfere with, disrupt, probe, or reverse engineer the App or its security, or
  use it to build a competing facial-recognition dataset;
- upload unlawful, harmful, or infringing content, or use the App in a way that
  violates any law or the rights of others.

Some features (such as content moderation and administration) are available only
to authorized Church staff and volunteers.

## 11. Withdrawing Consent, Deleting Your Account, and Termination

You may stop using the App at any time.

**To withdraw facial-recognition consent or delete your account,** use *My
Profile → Account → Delete my account*, which sends your request to the church
team. Deletion is handled personally by the team rather than by a self-service
button, precisely because facial data is involved. Once processed, your account
closes and your enrollment images and face embeddings are **permanently deleted**;
you are no longer matched by the attendance cameras.

You keep every alternative in Section 4 afterward, and there is no penalty for
withdrawing.

We may suspend or end access for anyone who violates these Terms, or to protect
members, the Church, or the App. On termination, the license granted to you ends;
sections that by their nature should survive (intellectual property, disclaimers,
and limitation of liability) continue to apply.

## 12. Disclaimers

The App and its identification system are provided **"as is" and "as available,"**
without warranties of any kind, express or implied, including implied warranties
of merchantability, fitness for a particular purpose, and non-infringement, to the
fullest extent permitted by law.

Performance may vary with environmental factors such as lighting, headwear,
eyewear, camera position, and sudden technical disruptions. We do not warrant that
the App will be uninterrupted, error-free, or secure, that attendance will always
be recorded correctly, or that reminders will always be delivered. The Church is
not liable for system outages, network failures, or technical errors that result
in missed or incorrect attendance logging.

## 13. Limitation of Liability

To the fullest extent permitted by law, **Rejoice Greatly Church, Inc.** and its
pastors, staff, volunteers, and service providers will not be liable for any
indirect, incidental, special, consequential, or punitive damages, or for lost
data or lost profits, arising out of or relating to your use of the App. Nothing
in these Terms limits liability that cannot be limited under applicable law,
including under any privacy or biometric-data law that applies to you.

## 14. Changes to These Terms

We may update these Terms from time to time. When we do, we will change the "Last
updated" date above and, where appropriate, notify you in the App. Material
changes to how we handle facial data will be made through the Privacy Policy and,
where required by law, with your renewed consent. Continuing to use the App after
an update means you accept the revised Terms.

## 15. Governing Law

These Terms are governed by the laws of the State of **Arizona** and the United
States, without regard to conflict-of-laws rules. Any dispute will be handled in
the state or federal courts located in Arizona, unless applicable law requires
otherwise.

## 16. Contact Us

Questions about these Terms? Reach us at **[SUPPORT CONTACT EMAIL]**, or by mail
at **[CHURCH MAILING ADDRESS]**.

---

*These Terms work alongside the Rejoice Greatly Privacy Policy, which explains in
detail how your facial data and other information are collected, used, protected,
retained, and deleted.*
