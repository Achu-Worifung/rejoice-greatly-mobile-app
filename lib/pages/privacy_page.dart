import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../util/legal_config.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/legal_document.dart';

/// Privacy Policy for the Rejoice Greatly app, with a US / BIPA-style biometric
/// section front and center.
///
/// Church-specific identity (legal name, contact, governing state, effective
/// date, retention period) comes from `.env` via [LegalConfig], so this text
/// can ship unchanged and be finalised through configuration.
///
/// The data practices described here are grounded in how the app and its
/// backing services actually work (Firebase Authentication; on-device face
/// guidance via ML Kit; client-side AES-256-GCM encryption of enrollment
/// photos; direct-to-Azure staging upload; server-side face validation;
/// on-premise facial recognition that stores only mathematical embeddings; and
/// OneSignal push/email reminders). It is a good-faith draft, not legal advice
/// — have counsel review it before release, especially for BIPA and any other
/// state biometric-privacy laws that apply to your congregation.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = LegalConfig.appName;
    final entity = LegalConfig.legalEntity;
    final email = LegalConfig.privacyEmail;

    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle('Privacy policy'),
      body: LegalDocument(
        title: 'Privacy Policy',
        effectiveDate: LegalConfig.effectiveDate,
        intro: [
          '$entity ("we," "us," or "the Church") built $app to help members '
              'stay close to church life. We take special care with your '
              'information — above all with the facial data used to record your '
              'attendance. This policy explains what we collect, why, how we '
              'protect it, how long we keep it, and the choices and rights you '
              'have.',
          'This policy is written for members in the United States. Because the '
              'App uses facial recognition, please read Section 3 (Biometric '
              'data) closely — it is the most important part.',
        ],
        sections: [
          LegalSection(
            heading: 'A quick summary',
            blocks: [
              const LegalBullet(
                'to recognize you and mark you present at services. Nothing '
                'else.',
                lead: 'We use your face only',
              ),
              const LegalBullet(
                'Your enrollment photos are encrypted on your device before '
                'they ever leave it, and the recognition system stores a '
                'mathematical representation of your face — not a photo album of '
                'members.',
              ),
              const LegalBullet(
                'We do not sell your data, we do not use your face for '
                'advertising, and we do not share your biometric data with third '
                'parties except the vendors that help us run the App.',
              ),
              const LegalBullet(
                'You can ask us to delete your facial data and your account at '
                'any time.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Information we collect',
            blocks: [
              const LegalSubheading('Account information'),
              const LegalBullet(
                'your name, email address, and a unique account identifier;',
              ),
              const LegalBullet(
                'your sign-in method (email/password, Google, or Apple), '
                'handled through Google Firebase Authentication;',
              ),
              const LegalBullet(
                'your profile photo (chosen from your enrollment capture).',
              ),
              const LegalSubheading('Facial (biometric) data'),
              const LegalParagraph(
                'Face images captured during enrollment and the face '
                'embeddings derived from them. This is covered in detail in '
                'Section 3.',
              ),
              const LegalSubheading('Attendance and activity'),
              const LegalBullet(
                'records of when you were recognized present, your attendance '
                'and absence counts, and your current and longest streaks;',
              ),
              const LegalBullet(
                'saved sermons and your interactions with events, reminders, '
                'and other features.',
              ),
              const LegalSubheading('Device and technical information'),
              const LegalBullet(
                'a push-notification identifier for your device (via OneSignal) '
                'so we can send reminders, and basic technical data needed to '
                'operate the App reliably.',
              ),
              const LegalParagraph(
                'We collect this information when you create an account, '
                'complete enrollment, attend a service, or use App features.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Biometric data — how we handle your face',
            blocks: [
              LegalParagraph(
                'This section is our biometric-privacy notice. "Biometric data" '
                'here means images of your face captured for enrollment and the '
                'face embeddings (mathematical representations) derived from '
                'them. We treat this as sensitive information and, where '
                'applicable, as a "biometric identifier" and "biometric '
                'information" under laws such as the Illinois Biometric '
                'Information Privacy Act (BIPA) and comparable state laws.',
              ),
              const LegalSubheading('Why we collect it'),
              const LegalParagraph(
                'We collect and use your facial data for one purpose: to '
                'recognize you at church services and record your attendance. '
                'We do not use it for any other purpose.',
              ),
              const LegalSubheading('Your consent'),
              const LegalParagraph(
                'We collect facial data only after you give informed, written '
                'consent. Before enrollment you are told that facial data is '
                'being collected, and by agreeing and completing the capture '
                'step you authorize the Church to collect, store, and use it as '
                'described here. Enrollment is voluntary; if you do not consent, '
                'you can still use the rest of the App, but facial-recognition '
                'attendance will not be available to you.',
              ),
              const LegalSubheading('How enrollment actually works'),
              const LegalBullet(
                'At sign-up, the App uses your front camera to capture several '
                'photos of your face from a few angles. On-device face '
                'detection (Google ML Kit) runs only to guide the capture — it '
                'stays on your device and is not sent anywhere.',
                lead: 'Capture:',
              ),
              const LegalBullet(
                'Each photo is encrypted on your device (AES-256-GCM) before it '
                'is uploaded. It travels over an encrypted connection to a '
                'temporary, private staging area; a leaked link would reveal '
                'only ciphertext.',
                lead: 'Encryption:',
              ),
              const LegalBullet(
                'The Church decrypts the photo only in memory to check that it '
                'contains a single, clear face, then saves a private profile '
                'image and creates the face embedding used for recognition. The '
                'temporary encrypted upload is deleted right after; unused '
                'uploads are automatically swept and deleted.',
                lead: 'Validation:',
              ),
              const LegalBullet(
                'The on-premise recognition system pulls your enrollment images '
                'into memory only, converts them into face embeddings, and '
                'stores those embeddings in a local index. It does not save the '
                'headshots to disk. On service days it matches faces from '
                'on-site cameras and marks recognized members present.',
                lead: 'Recognition:',
              ),
              const LegalSubheading('Who can see it'),
              const LegalParagraph(
                'Your facial data is not visible to other members. Stored '
                'images are kept in private storage and are never publicly '
                'accessible. Only authorized Church administrators and the '
                'systems that run enrollment and recognition can access '
                'biometric data and attendance records, and only to operate '
                'attendance.',
              ),
              const LegalSubheading('We do not sell it'),
              const LegalParagraph(
                'We do not sell, lease, trade, or otherwise profit from your '
                'biometric data, and we will not disclose it except: with your '
                'consent; to the service providers who help us run the App '
                '(Section 5), under contracts that restrict their use; or if '
                'required by law, warrant, or subpoena.',
              ),
              const LegalSubheading('Retention and destruction'),
              LegalParagraph(
                'We keep your biometric data only as long as needed for '
                'attendance, and no longer than the earlier of: (a) the purpose '
                'for collecting it has been satisfied — for example, you delete '
                'your account or withdraw consent — or (b) 3 years after your '
                'last interaction with the Church, consistent with BIPA. When '
                'that point is reached, we permanently delete your enrollment '
                'images and face embeddings on a schedule that reflects this '
                'policy.',
              ),
            ],
          ),
          LegalSection(
            heading: 'How we use your information',
            blocks: [
              const LegalBullet(
                'to create and secure your account and sign you in;',
              ),
              const LegalBullet(
                'to recognize you and record and display your attendance, '
                'streaks, and history;',
              ),
              const LegalBullet(
                'to send push notifications and email reminders you have allowed '
                '(for example, upcoming events or a sermon you missed);',
              ),
              const LegalBullet(
                'to provide sermons, events, the weekly verse, the café, and '
                'other features;',
              ),
              const LegalBullet(
                'to keep the App safe, prevent misuse, and comply with our legal '
                'obligations.',
              ),
              const LegalParagraph(
                'We do not use your information for third-party advertising, and '
                'we never use your face for anything other than attendance.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Service providers we share with',
            blocks: [
              const LegalParagraph(
                'We use trusted vendors to run the App. They may process your '
                'information only to provide their service to us, under '
                'agreements that limit how they use it:',
              ),
              const LegalBullet(
                'sign-in and account authentication.',
                lead: 'Google Firebase —',
              ),
              const LegalBullet(
                'the "Sign in with" option you choose.',
                lead: 'Google / Apple —',
              ),
              const LegalBullet(
                'encrypted storage of profile and enrollment images and '
                'protection of encryption keys.',
                lead: 'Microsoft Azure (Blob Storage / Key Vault) —',
              ),
              const LegalBullet(
                'push notifications and email reminders.',
                lead: 'OneSignal —',
              ),
              const LegalBullet(
                'the connected café experience opened from the App.',
                lead: 'Mood Changing Café (hosted on Vercel) —',
              ),
              const LegalParagraph(
                'On-site attendance cameras and the recognition software run on '
                'equipment operated by the Church. We do not share your '
                'biometric data with any party for that party\'s own purposes.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Data stored on your device',
            blocks: [
              const LegalParagraph(
                'To keep the App fast and usable offline, we store some '
                'information on your device, such as your name, email, profile '
                'image link, attendance totals, and saved sermons. This is '
                'cleared when you sign out. Signing out of your account also '
                'clears the café session on your device.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Your choices and rights',
            blocks: [
              const LegalSubheading('Everyone'),
              const LegalBullet(
                'Access and correction — ask what we hold about you, or fix '
                'inaccurate details, including a wrong attendance record.',
              ),
              const LegalBullet(
                'Delete your facial data — withdraw your enrollment consent and '
                'have your face images and embeddings deleted, while keeping the '
                'rest of your account if you wish.',
              ),
              const LegalBullet(
                'Delete your account — remove your account and associated '
                'personal data, subject to records we must keep by law.',
              ),
              const LegalBullet(
                'Turn off notifications — in your device settings at any time.',
              ),
              const LegalSubheading('State privacy rights'),
              const LegalParagraph(
                'Depending on where you live, you may have additional rights '
                'under your state\'s privacy law — for example, to know, access, '
                'correct, delete, or obtain a copy of your personal information, '
                'and to not be discriminated against for exercising those '
                'rights. Facial data is treated as sensitive information, and we '
                'use it only for the attendance purpose you consented to. To '
                'exercise any right, contact us using Section 11; we will verify '
                'your request before acting on it.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Security',
            blocks: [
              const LegalParagraph(
                'We use reasonable administrative, technical, and physical '
                'safeguards to protect your information — including encrypting '
                'enrollment photos on your device before upload, encrypting data '
                'in transit, keeping images in private (non-public) storage, '
                'protecting encryption keys, and limiting access to authorized '
                'people and systems. We store and protect your biometric data '
                'using at least the same care we use for other confidential '
                'information. No system is perfectly secure, but we work to '
                'protect your data to the standard the law requires for '
                'biometric information.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Children',
            blocks: [
              const LegalParagraph(
                'The App is for adults 18 and older. We do not knowingly collect '
                'personal or biometric information from anyone under 18. If we '
                'learn that we have, we will delete it. If you believe a minor '
                'has provided information, contact us (Section 11).',
              ),
            ],
          ),
          LegalSection(
            heading: 'Changes to this policy',
            blocks: [
              const LegalParagraph(
                'We may update this policy. When we do, we will change the "Last '
                'updated" date above and, for material changes to how we handle '
                'facial data, notify you in the App and — where the law requires '
                'it — ask for your consent again before the change affects you.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Contact us',
            blocks: [
              LegalParagraph(
                'For any privacy question, or to access, correct, or delete your '
                'data (including your facial data), contact us at $email, or by '
                'mail at ${LegalConfig.mailingAddress}. We will respond within '
                'the timeframe the law requires.',
              ),
            ],
          ),
        ],
        footer: [
          const LegalParagraph(
            'In plain terms: your face is used to check you in at church, and '
            'nothing else. It is encrypted on your phone, stored as a '
            'mathematical representation, kept private, and deleted when you '
            'ask or when we no longer need it.',
          ),
        ],
      ),
    );
  }
}
