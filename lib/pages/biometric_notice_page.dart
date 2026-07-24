import 'package:flutter/material.dart';

import '../widgets/legal_document_view.dart';

/// The Biometric Information Notice shown before facial enrollment, and
/// available afterwards from My Profile → Account.
///
/// The canonical copy lives in `docs/BIOMETRIC_NOTICE_AND_CONSENT.md`; the
/// consent gate that links here is in `lib/pages/user_prep.dart`. Edit all
/// three together.
class BiometricNoticePage extends StatelessWidget {
  const BiometricNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final church = LegalValues.legalEntity;
    final app = LegalValues.appName;

    return LegalDocumentView(
      appBarTitle: 'Biometric notice',
      title: 'Biometric Information Notice & Consent',
      lastUpdated: LegalValues.lastUpdated,
      intro: [
        LegalParagraph(
          'This Notice explains how $church collects, uses, stores, protects, '
          'and deletes facial verification information when you choose to enroll '
          'in face check-in for the $app app. Please read it before enabling '
          'facial recognition.',
        ),
        const LegalCallout(
          icon: Icons.how_to_reg_outlined,
          title: 'Your face is used for one thing: marking you present',
          text: 'It is not how you sign in. Signing in uses your email and '
              'password, or Sign in with Google or Apple, and that does not '
              'change if you enroll. Your face is never a password.',
        ),
      ],
      sections: [
        LegalSection('Enrollment is voluntary', [
          const LegalParagraph(
            'Facial recognition is optional, and it is offered only to members 18 '
            'and older. You can check in two other ways that involve no facial '
            'data at all:',
            lead: true,
          ),
          const LegalBullets([
            'Tap the NFC tag at the entrance with your phone.',
            'Check in with a person at the information desk or with a greeter.',
          ]),
          const LegalParagraph(
            'Declining facial recognition does not limit the rest of the app, and '
            'it carries no penalty, no restriction of entry, and no loss of '
            'church privileges. Using the app is not a requirement to attend '
            'anything.',
          ),
          const LegalCallout(
            icon: Icons.shield_outlined,
            title: 'If you do not enroll, no face template is ever created',
            text: 'Members under 18, members who use NFC or a greeter, visitors, '
                'guests, and people who do not use the app are not identified by '
                'the attendance cameras and have no biometric record.',
          ),
        ]),
        LegalSection('What we collect', [
          const LegalParagraph(
            'If you voluntarily enroll, we collect:',
          ),
          const LegalBullets([
            'A series of facial photographs captured during enrollment, taken '
                'with the front camera of your own phone. The app asks you to '
                'look forward and turn your head through a few angles — this '
                'improves accuracy and makes it harder to fool the system with a '
                "photograph of someone else.",
            'A face embedding derived from those photographs: a mathematical '
                'representation of your face, which is what the system actually '
                'matches against.',
            'Technical details needed to record attendance, such as the date and '
                'time you were recognized, and basic device information from the '
                'enrollment session.',
          ]),
          const LegalParagraph(
            'About the cameras at church. On service days, cameras operated by '
            'the Church compare the faces they see against the embeddings of '
            'enrolled members and mark recognized members present. The system '
            'holds those embeddings in memory and does not save headshots from '
            'the cameras to disk.',
          ),
          const LegalParagraph(
            'Members under 18 are not asked to enroll and are not asked for '
            'facial photographs.',
          ),
        ]),
        LegalSection('Why we collect it', [
          const LegalParagraph(
            'Your facial verification information is used solely to:',
          ),
          const LegalBullets([
            'Recognize you at church and record your attendance;',
            'Keep your attendance record accurate; and',
            'Detect and prevent someone logging attendance as you.',
          ]),
          const LegalParagraph(
            'It is not used for advertising, marketing, profiling, unrelated '
            'analytics, or any purpose beyond attendance. It is not used to '
            'unlock your account, and it is not shared with other members.',
          ),
        ]),
        LegalSection('How your photographs are handled', [
          const LegalBullets([
            'Encrypted on your phone — each enrollment photo is encrypted on '
                'your device (AES-256-GCM) before it is uploaded, and travels '
                'over an encrypted connection to a temporary, private staging '
                'area. Anyone who intercepted the link would see only '
                'ciphertext.',
            'Decrypted only in memory — we decrypt each photo just long enough '
                'to confirm it contains a single, clear face, then save a private '
                'image and create your face embedding.',
            'Staging cleaned up immediately — the temporary encrypted upload is '
                'deleted right after; uploads abandoned partway are automatically '
                'swept and deleted.',
            'Kept private — stored images live in private storage that is never '
                'publicly accessible.',
          ]),
        ]),
        LegalSection('Storage and protection', [
          const LegalParagraph(
            'We protect facial verification information with:',
          ),
          const LegalBullets([
            'Encryption in transit and at rest, with protected encryption keys',
            'Client-side encryption before photos leave your device',
            'Private, non-public image storage',
            'Access controls limiting authorized personnel and systems',
            'Authentication and authorization safeguards',
            'Security monitoring, logging, and regular security updates',
          ]),
          const LegalParagraph(
            'Only authorized administrators and the systems that run enrollment '
            'and recognition can reach biometric data and attendance records, and '
            'only to operate attendance. No security system can guarantee '
            'absolute protection, but we maintain commercially reasonable '
            'administrative, technical, and organizational safeguards.',
          ),
        ]),
        LegalSection('Alternatives, and changing your mind', [
          const LegalParagraph(
            'You may stop using face check-in at any time and switch to tapping '
            'the NFC tag at the entrance or checking in with a greeter. Neither '
            'requires you to give up anything else in the app, and neither '
            'involves biometric data.',
          ),
        ]),
        LegalSection('Retention and deletion', [
          const LegalParagraph(
            'We keep facial verification information only as long as it is needed '
            'to recognize you at church.',
          ),
          const LegalCallout(
            icon: Icons.auto_delete_outlined,
            title: 'When that purpose ends, it is destroyed',
            text: 'If you withdraw your consent or delete your account, your '
                'enrollment images and face embeddings are permanently deleted, '
                'and the attendance cameras no longer match you. You do not have '
                'to wait for any retention period to run out — ask us and we '
                'delete it, unless a longer period is required by law.',
          ),
        ]),
        LegalSection('Sharing', [
          const LegalParagraph(
            'We do not sell, lease, trade, or otherwise profit from your facial '
            'verification information. We disclose it only:',
          ),
          const LegalBullets([
            'To service providers acting on our behalf under contractual '
                'confidentiality obligations;',
            'To comply with applicable law or valid legal process; or',
            'To investigate fraud or protect the safety, rights, or security of '
                'our members.',
          ]),
          const LegalParagraph(
            'The attendance cameras and recognition software run on equipment '
            'operated by the Church. We do not share your biometric data with any '
            "party for that party's own purposes.",
          ),
        ]),
        LegalSection('Your choices', [
          const LegalParagraph('You have the right to:'),
          const LegalBullets([
            'Decline facial enrollment entirely;',
            'Check in by NFC tap or with a greeter instead;',
            'Withdraw your consent at any time;',
            'Request deletion of your facial verification photographs and '
                'embeddings;',
            'Ask us to correct an attendance record that is wrong.',
          ]),
          const LegalParagraph(
            'To withdraw consent or request deletion, use My Profile → Account → '
            'Delete my account, which sends your request to the church team, or '
            'contact us below. Withdrawing consent disables face check-in for '
            'you; every other way of checking in stays open.',
          ),
        ]),
        LegalSection('Consent', [
          const LegalParagraph(
            'By selecting "I Agree" and continuing with facial enrollment, you '
            'acknowledge that:',
            lead: true,
          ),
          LegalBullets([
            'You have read and understand this Biometric Information Notice.',
            'You voluntarily consent to $church collecting, processing, storing, '
                'and using your facial verification information as described '
                'here, and you authorize the creation of a face embedding from '
                'your enrollment photographs.',
            'You understand it is used solely to recognize you at church and '
                'record your attendance, and not to sign you in or unlock your '
                'account.',
            'You understand enrollment is optional, that NFC and in-person '
                'check-in are available to you instead, and that declining '
                'carries no penalty.',
            'You understand you may withdraw this consent at any time and have '
                'your facial data deleted.',
            'You confirm that you are at least 18 years of age.',
          ]),
          const LegalParagraph(
            'If you do not agree, do not enable facial recognition. Tap the NFC '
            'tag at the entrance or check in with a greeter instead — you are '
            'just as welcome either way.',
          ),
        ]),
        LegalSection('Contact', [
          const LegalParagraph(
            'Questions about this Notice, or want to exercise any of the choices '
            'above?',
          ),
          LegalContacts(email: LegalValues.privacyEmail),
        ]),
      ],
    );
  }
}
