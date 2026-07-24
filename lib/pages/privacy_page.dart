import 'package:flutter/material.dart';

import '../widgets/legal_document_view.dart';

/// Member-facing Privacy Policy.
///
/// The canonical copy lives in `docs/PRIVACY_POLICY.md` — edit both together.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final church = LegalValues.legalEntity;
    final app = LegalValues.appName;

    return LegalDocumentView(
      appBarTitle: 'Privacy policy',
      title: 'Privacy Policy',
      lastUpdated: LegalValues.lastUpdated,
      intro: [
        LegalParagraph(
          'Welcome to $app, operated by $church. This policy explains what '
          'information we collect, how we use it, how we protect it, how long we '
          'keep it, and the choices you have. It is written for members in the '
          'United States.',
        ),
        const LegalCallout(
          icon: Icons.favorite_outline_rounded,
          title: 'The short version',
          text: 'Facial recognition is one of three ways to check in. It is '
              'offered only to members 18 and older, it is entirely optional, '
              'and if you never enroll, we never create a face template for you.',
        ),
      ],
      sections: [
        LegalSection('Information we collect', [
          const LegalParagraph('Account information. When you create an account, '
              'we may collect:'),
          const LegalBullets([
            'Name',
            'Email address',
            'Username or display name',
            'Your date of birth',
            'Your sign-in method (email/password, Google, or Apple)',
          ]),
          const LegalParagraph(
            'We ask for your date of birth for one purpose: to determine whether '
            'the facial scan is offered to you at all. Members under 18 skip it.',
          ),
          const LegalParagraph(
            'Sign-in is handled through Google Firebase Authentication. If you '
            'use email and password, your password is created, managed, and '
            'protected by Firebase using industry-standard cryptographic '
            'hashing; we never receive or store it in plain text.',
          ),
          const LegalParagraph(
            'Profile information. You may choose to provide a profile photo, a '
            'display name, and other details. Your profile photo is separate '
            'from any facial verification records — it is only for display, and '
            'is never used for recognition.',
          ),
          const LegalParagraph(
            'Facial verification data, only if you enroll. If you are 18 or '
            'older and choose to enroll, we collect a series of facial '
            'photographs captured on your own device while you look forward, '
            'turn your head, and change viewing angles. From these we derive a '
            'face embedding — a mathematical representation of your face — used '
            'solely to verify your identity and record your attendance. We do '
            'not collect facial data from members under 18, or from anyone who '
            'does not enroll.',
          ),
          const LegalParagraph(
            "NFC check-in. When you tap your phone on the tag at the entrance, "
            "we collect the tag's identifier and the time, and record that your "
            'signed-in account was present. NFC check-in involves no biometrics '
            'and reads nothing off your person.',
          ),
          const LegalParagraph(
            'Attendance and activity. We collect records of when you were '
            'recognized or checked in present, your attendance and absence '
            'counts, your current and longest streaks, saved sermons, and your '
            'interactions with events and reminders.',
          ),
          const LegalParagraph(
            'Device and technical information. We may automatically collect '
            'device model and operating system, app version, crash reports and '
            'diagnostics, security logs, and a push-notification identifier for '
            'your device (via OneSignal).',
          ),
        ]),
        LegalSection('How we use your information', [
          const LegalParagraph('We use collected information to:'),
          const LegalBullets([
            'Create and manage your account',
            'Verify your identity and record your attendance',
            'Secure access to the app and detect fraud or unauthorized access',
            'Improve authentication and recognition accuracy',
            'Maintain system security and reliability',
            'Send push notifications and email reminders you have allowed',
            'Provide sermons, events, the weekly verse, the café, and other '
                'features',
            'Provide support and comply with our legal obligations',
          ]),
          const LegalParagraph(
            'We do not use facial verification photographs or face embeddings '
            'for advertising, marketing, or user profiling.',
          ),
        ]),
        LegalSection('Facial recognition and biometric data', [
          const LegalParagraph(
            'This section is our biometric-privacy notice. "Biometric data" here '
            'means the facial photographs captured during enrollment and the '
            'face embeddings derived from them.',
          ),
          LegalCallout(
            icon: Icons.gavel_outlined,
            title: 'We hold ourselves to the strictest standard',
            text: '${LegalValues.governingState} does not currently have a '
                'dedicated biometric privacy statute of the kind some states '
                'have enacted. We follow those standards anyway: we treat your '
                'facial data as sensitive personal information, tell you before '
                'we collect it, collect it only with your consent, use it for '
                'one stated purpose, never sell it, and destroy it once that '
                'purpose ends.',
          ),
          const LegalParagraph(
            'Who this applies to. Only members 18 and older who choose to '
            'enroll. Enrollment is voluntary, it is not required to use the app, '
            'and it is not required to attend anything.',
          ),
          const LegalParagraph(
            'Purpose. Facial verification data is processed exclusively to '
            'verify your identity and record your attendance at church '
            'services. We do not use it for any other purpose.',
          ),
          LegalParagraph(
            'Your consent. We collect facial data only after you give informed '
            'consent. Before enrollment you are told that facial data is being '
            'collected and why, and by agreeing and completing the capture step '
            'you authorize $church to collect, store, and use it as described '
            'here.',
          ),
          const LegalParagraph('How enrollment actually works:'),
          const LegalBullets([
            'Capture — at sign-up, the app uses the front camera of your own '
                'phone to take several photos of your face from a few angles. '
                'On-device face detection (Google ML Kit) runs only to guide the '
                'capture; it stays on your device and is not sent anywhere.',
            'Encryption — each photo is encrypted on your device (AES-256-GCM) '
                'before it is uploaded, and travels over an encrypted connection '
                'to a temporary, private staging area. A leaked link would '
                'reveal only ciphertext.',
            'Validation — we decrypt the photo only in memory to confirm it '
                'contains a single, clear face, then save a private image and '
                'create the face embedding used for recognition. The temporary '
                'upload is deleted immediately afterward; abandoned uploads are '
                'automatically swept and deleted.',
            'Recognition — the on-premise system loads enrollment images into '
                'memory only, converts them into embeddings, and keeps those in '
                'a local index. It does not save headshots to disk. On service '
                'days it matches faces seen by on-site cameras against that '
                'index and marks recognized members present.',
          ]),
          const LegalCallout(
            icon: Icons.shield_outlined,
            title: 'If you have not enrolled, you have no face template',
            text: 'The attendance cameras match only against the embeddings of '
                'members who opted in. Members under 18, members who use NFC or '
                'a greeter instead, visitors, guests, and anyone who does not '
                'use the app are not identified, not enrolled, and have no '
                'biometric record created — ever. A face the system has no '
                'embedding for is simply not a match, and nothing about it is '
                'stored.',
          ),
          const LegalParagraph(
            'Who can see it. Your facial data is not visible to other members. '
            'Stored images are kept in private storage that is never publicly '
            'accessible. Only authorized administrators and the systems that run '
            'enrollment and recognition can access biometric data and attendance '
            'records, and only to operate attendance.',
          ),
          const LegalParagraph(
            'We do not sell it. We do not sell, lease, trade, or otherwise '
            'profit from your biometric data.',
          ),
          const LegalParagraph(
            'Retention and destruction. We keep your biometric data only as long '
            'as it is needed for the purpose described above — recognizing you '
            'at church. When that purpose ends, it is destroyed: if you delete '
            'your account or withdraw your consent, we permanently delete your '
            'enrollment images and face embeddings. You never have to wait for a '
            'clock to run out — ask us and we delete it.',
          ),
        ]),
        LegalSection('Cameras, photography, and recording on our premises', [
          const LegalParagraph(
            'This section describes what happens on the property, separate from '
            'the app.',
          ),
          const LegalCallout(
            icon: Icons.videocam_outlined,
            title: 'Notice of video recording and photography',
            text: 'For the safety and security of our congregation and '
                'facilities, this property is monitored by video surveillance 24 '
                'hours a day, 7 days a week.\n\nWorship services, church events, '
                'and activities may also be photographed and/or recorded for '
                'ministry, promotional, livestream, website, and social media '
                'purposes. By entering the premises, you acknowledge that your '
                'image, voice, or likeness may be captured.\n\nIf you prefer not '
                'to appear in photographs, videos, livestreams, or social media '
                'content, please notify a church leader or a member of the media '
                'team so that reasonable accommodations can be made.',
          ),
          const LegalParagraph(
            'These are not facial recognition. Security footage and ministry '
            'photography are not run through the recognition system, are not '
            'used to create or improve face embeddings, and are not linked to '
            'your app account or attendance record. Being filmed at a service '
            'does not enroll you in anything.',
          ),
        ]),
        LegalSection('Children and members under 18', [
          const LegalParagraph(
            'The app is open to the whole congregation, including members under '
            '18 — they can follow sermons, events, the weekly verse, and their '
            'attendance like anyone else.',
          ),
          const LegalCallout(
            icon: Icons.child_care_outlined,
            title: 'We do not collect biometric data from anyone under 18',
            text: 'When the date of birth given at sign-up is under 18, the app '
                'skips facial enrollment entirely: no facial photographs are '
                'captured, no embedding is created, and the attendance cameras '
                'have nothing to match against. Younger members check in by NFC '
                'tap or with a greeter.',
          ),
          const LegalParagraph(
            'For children under 13, a parent or guardian should create and '
            'supervise the account, and by doing so consents to the collection '
            'of that account information. If you are a parent or guardian and '
            "would like to review or delete your child's information, contact us "
            'and we will do so.',
          ),
        ]),
        LegalSection('Data security', [
          const LegalParagraph(
            'We employ multiple layers of security designed to protect your '
            'information, including:',
          ),
          const LegalBullets([
            'Encryption in transit using secure communication protocols',
            'Client-side encryption of enrollment photos before they leave your '
                'device',
            'Encryption at rest for stored data, with protected encryption keys',
            'Private, non-public storage for images',
            'Access controls limiting authorized personnel and systems',
            'Authentication and authorization safeguards',
            'Security monitoring and logging, and regular security updates',
          ]),
          const LegalParagraph(
            'We store and protect biometric data using at least the same care we '
            'use for other confidential information. While we strive to protect '
            'your information using commercially reasonable measures, no method '
            'of electronic storage or transmission is completely secure.',
          ),
        ]),
        LegalSection('Data sharing', [
          const LegalParagraph(
            'We do not sell your personal information or facial verification '
            'photographs. We share information only:',
          ),
          const LegalBullets([
            'With cloud infrastructure and service providers that help us '
                'operate the app, under contracts that restrict their use of it '
                '— including Google Firebase (authentication), Google and Apple '
                '(the "Sign in with" option you choose), Microsoft Azure '
                '(encrypted image storage and key protection), OneSignal (push '
                'and email reminders), and the Mood Changing Café (the connected '
                'café opened from the app)',
            'When required by law, or in response to a valid legal request',
            'To protect members, investigate fraud, or enforce our agreements',
          ]),
          const LegalParagraph(
            'On-site attendance cameras and the recognition software run on '
            'equipment operated by the Church. We do not share your biometric '
            "data with any party for that party's own purposes.",
          ),
        ]),
        LegalSection('Data retention', [
          const LegalParagraph(
            'We retain your information only as long as necessary to provide our '
            'services, maintain account and attendance security, meet legal '
            'obligations, and resolve disputes. Biometric data is retained as '
            'described above. If you delete your account, we will delete or '
            'anonymize your personal information within a reasonable period, '
            'unless retention is required by law.',
          ),
        ]),
        LegalSection('Your rights and choices', [
          const LegalParagraph(
            'Depending on where you live, you may have the right to:',
          ),
          const LegalBullets([
            'Access your information, and obtain a copy of it',
            'Correct inaccurate information, including a wrong attendance record',
            'Delete your account',
            'Request deletion of your facial verification photographs and '
                'embeddings',
            'Withdraw consent for facial recognition at any time',
            'Check in by NFC or with a greeter instead of facial recognition',
            'Not be discriminated against for exercising any of these rights',
          ]),
          const LegalCallout(
            icon: Icons.how_to_reg_outlined,
            title: 'How to exercise them',
            text: 'Use My Profile → Account → Delete my account to send your '
                'request to the church team, or contact us using the details '
                'below. Deletion is handled personally by the team rather than '
                'by a self-service button, precisely because facial data is '
                'involved. We will verify your request before acting on it and '
                'respond within the timeframe the law requires.',
          ),
          const LegalParagraph(
            'Withdrawing consent for facial recognition disables face check-in '
            'for you and deletes your embeddings. Every other way of checking in '
            'stays open, with no penalty and no loss of church privileges.',
          ),
        ]),
        LegalSection('International transfers', [
          const LegalParagraph(
            'Your information may be processed or stored in countries other than '
            'your own. Where required by applicable law, we implement safeguards '
            'designed to protect personal information during international '
            'transfers.',
          ),
        ]),
        LegalSection('Changes to this policy', [
          const LegalParagraph(
            'We may update this Privacy Policy periodically. When we do, we will '
            'change the "Last updated" date above and communicate material '
            'changes through the app or by other appropriate means. For material '
            'changes to how we handle facial data, we will notify you in the app '
            'and — where the law requires it — ask for your consent again before '
            'the change affects you.',
          ),
        ]),
        LegalSection('Contact us', [
          const LegalParagraph(
            'For any privacy question, or to access, correct, or delete your '
            'data including your facial data, contact us at:',
          ),
          LegalContacts(email: LegalValues.privacyEmail),
        ]),
      ],
    );
  }
}
