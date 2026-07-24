import 'package:flutter/material.dart';

import '../widgets/legal_document_view.dart';

/// Member-facing Terms of Use.
///
/// The canonical copy lives in `docs/TERMS_OF_USE.md` — edit both together.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final church = LegalValues.legalEntity;
    final app = LegalValues.appName;

    return LegalDocumentView(
      appBarTitle: 'Terms of use',
      title: 'Terms of Use',
      lastUpdated: LegalValues.lastUpdated,
      intro: [
        LegalParagraph(
          'These Terms of Use are an agreement between you and $church '
          '("we," "us," or "the Church") and govern your use of the $app app '
          'and the features within it.',
        ),
        const LegalParagraph(
          'Please read them together with our Privacy Policy, which explains how '
          'we handle your information — including the facial (biometric) data '
          'used to record attendance. By creating an account or using the app, '
          'you agree to both.',
        ),
      ],
      sections: [
        LegalSection('Who can use the app', [
          const LegalParagraph(
            'The app is for the whole congregation. There is no minimum age to '
            'have an account — members of every age are welcome to use it to '
            'follow sermons, events, the weekly verse, and their attendance.',
            lead: true,
          ),
          const LegalCallout(
            icon: Icons.cake_outlined,
            title: 'Age matters in exactly one place',
            text: 'Facial recognition is offered only to members 18 and older. '
                'That is the only reason we ask for your date of birth at '
                'sign-up. Members under 18 skip the facial scan entirely and go '
                'straight into the app.',
          ),
          const LegalParagraph('You confirm that:'),
          const LegalBullets([
            'the information you give us at sign-up, including your date of '
                'birth, is true and belongs to you;',
            'you will keep your sign-in credentials confidential and are '
                'responsible for activity under your account; and',
            'if you are under 18, a parent or guardian is aware of and consents '
                'to your use of the app. For children under 13, a parent or '
                'guardian should create and supervise the account.',
          ]),
        ]),
        LegalSection('The app is free', [
          LegalParagraph(
            'The app is provided to the congregation free of charge. There is no '
            'subscription, membership fee, or payment of any kind required to '
            'use $app or any of its check-in methods. The Mood Changing Café may '
            'sell items under its own terms.',
          ),
        ]),
        LegalSection('Your account and sign-in', [
          const LegalParagraph(
            'You can create an account with your email and a password, or by '
            'using Sign in with Google or Sign in with Apple. Sign-in is handled '
            'through Google Firebase Authentication. You are responsible for '
            'the security of the email account or provider you sign in with.',
          ),
        ]),
        LegalSection('Checking in — and your choice of how', [
          const LegalParagraph(
            'Recording attendance is a core purpose of the app. How you check in '
            'is entirely your choice, and every option carries the same weight:',
          ),
          const LegalBullets([
            'Facial recognition — for members 18 and older who opt in. You '
                'enroll once from your own phone; on service days, cameras '
                'operated by the Church at its premises match enrolled members '
                'and mark them present.',
            "NFC tap — tap your phone on the tag at the entrance and you're "
                "marked present. No facial data is involved: the app reads the "
                "tag's identifier, not anything off you.",
            'In person — check in at the information desk or with a greeter.',
          ]),
          const LegalCallout(
            icon: Icons.volunteer_activism_outlined,
            title: 'Automated attendance is entirely voluntary',
            text: 'Using the app is not a requirement to attend worship '
                'services or events, or to be part of our church family. '
                'Choosing a manual alternative results in no penalty, no '
                'restriction of entry, and no loss of church privileges of any '
                'kind.',
          ),
          const LegalParagraph(
            'Please understand that recognition is not perfect. Lighting, pose, '
            'camera position, headwear, eyewear, appearance changes, and NFC '
            'read errors can cause a missed or incorrect match. Attendance '
            'records are a convenience and may contain errors — contact the '
            'Church and we will correct your record.',
          ),
        ]),
        LegalSection('Consent to facial (biometric) processing', [
          const LegalParagraph(
            'This section applies only if you are 18 or older and choose to '
            'enroll. If you do not enroll, nothing in it applies to you.',
            lead: true,
          ),
          const LegalParagraph(
            'Eligibility. Facial recognition is an optional authentication '
            'feature available only to eligible users who attend participating '
            'church locations where the feature has been deployed. To protect '
            'user privacy and comply with applicable laws, facial recognition '
            'enrollment is not available to:',
          ),
          const LegalBullets([
            'Individuals under 18 years of age.',
            'Users who do not attend a participating church location.',
            'Users located in jurisdictions where we have chosen not to offer '
                'facial recognition due to legal, regulatory, or operational '
                'considerations.',
            'Users whose accounts are not authorized for facial recognition by '
                'the participating church.',
          ]),
          const LegalParagraph(
            'If you are not eligible, do not enroll. You will authenticate using '
            'another supported method, such as an NFC security tag, and nothing '
            'else in the app is affected. By enrolling, you represent that you '
            'meet the eligibility requirements above.',
          ),
          const LegalCallout(
            icon: Icons.place_outlined,
            title: 'For use at participating church locations only',
            text: 'Facial recognition is intended solely for use on the grounds '
                'of participating church locations during authorized church '
                'activities. It is not designed or intended for general-purpose '
                'identity verification outside of those locations, and it is not '
                'offered as an identity-verification service to anyone.',
          ),
          LegalParagraph(
            'By completing the facial enrollment step, you give explicit, '
            'informed consent for $church to:',
          ),
          const LegalBullets([
            'capture several photographs of your face using the front camera of '
                'your own device, at sign-up, while you look forward and turn '
                'your head through a few angles;',
            'convert those photographs into an encrypted mathematical '
                'representation (a "face embedding") stored for automated '
                'attendance; and',
            'use cameras positioned at church entrances on service days to '
                'match your face against that stored embedding and mark you '
                'present.',
          ]),
          const LegalCallout(
            icon: Icons.verified_user_outlined,
            title: 'We only recognize people who have enrolled',
            text: 'If you have not enrolled — because you use NFC, check in '
                'with a greeter, are under 18, or do not use the app at all — no '
                'face template is ever created for you, and the attendance '
                'system does not attempt to identify you. Visitors and guests '
                'are never enrolled.',
          ),
          const LegalParagraph(
            'Your consent is not a condition of anything else. You may withdraw '
            'it at any time, and the other ways to check in remain fully open '
            'to you.',
          ),
        ]),
        LegalSection('Members under 18', [
          const LegalParagraph(
            'Members under 18 are welcome in the app. When the date of birth '
            'entered at sign-up is under 18, the app does not offer facial '
            'enrollment, does not capture facial photographs, and does not '
            'create biometric data — that step is skipped and the member goes '
            'straight to the dashboard. Younger members check in by NFC tap or '
            'with a greeter.',
          ),
          const LegalParagraph(
            "If you believe a minor's account has facial data associated with "
            'it, contact us and we will delete it.',
          ),
        ]),
        LegalSection('Cameras, photography, and recording on our premises', [
          const LegalParagraph(
            'Separate from the app, and applying to everyone on the property:',
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
            'Security video and ministry photography are not the same as the '
            "app's attendance recognition. They are not used to build face "
            'embeddings and are not connected to your app account.',
          ),
        ]),
        LegalSection('Sermons, events, reminders, and content', [
          const LegalParagraph(
            'The app lets you play sermons and audio, browse and get reminders '
            'about events, view a weekly verse, track attendance streaks, and '
            'access community features. Content in the app remains the property '
            'of the Church or its licensors and is provided for your personal, '
            'non-commercial use.',
          ),
          const LegalParagraph(
            'With your permission, the app sends push notifications and email '
            'reminders. You can turn notifications off in your device settings '
            'at any time.',
          ),
        ]),
        LegalSection('The Mood Changing Café', [
          const LegalParagraph(
            'The app includes a café area that opens the Mood Changing Café, a '
            'connected web experience. When you are signed in, the app can pass '
            'your sign-in securely into the café so you do not have to log in '
            'again. The café is a separate service with its own features and may '
            'have its own terms, which apply in addition to these.',
          ),
        ]),
        LegalSection('Acceptable use', [
          const LegalParagraph('You agree not to:'),
          const LegalBullets([
            "enroll, or attempt to have recognized, anyone's face but your own "
                '— you may only enroll your own face, or the face of a legal '
                'dependent for whom you have lawful authority to give consent;',
            'bypass, spoof, trick, or disrupt the recognition system — for '
                'example, holding up a photograph of another person, or tapping '
                "the entrance tag on someone else's behalf, to log attendance;",
            'impersonate another person, or access accounts, attendance '
                'records, or Church systems that are not yours, including admin '
                'or moderation tools;',
            'interfere with, disrupt, probe, or reverse engineer the app or its '
                'security, or use it to build a competing facial-recognition '
                'dataset;',
            'upload unlawful, harmful, or infringing content, or use the app in '
                'a way that violates any law or the rights of others.',
          ]),
          const LegalParagraph(
            'Some features, such as content moderation and administration, are '
            'available only to authorized Church staff and volunteers.',
          ),
        ]),
        LegalSection('Withdrawing consent, deleting your account, and termination', [
          const LegalParagraph('You may stop using the app at any time.'),
          const LegalCallout(
            icon: Icons.delete_outline_rounded,
            title: 'How to withdraw consent or delete your account',
            text: 'Use My Profile → Account → Delete my account, which sends '
                'your request to the church team. Deletion is handled personally '
                'by the team rather than by a self-service button, precisely '
                'because facial data is involved. Once processed, your account '
                'closes and your enrollment images and face embeddings are '
                'permanently deleted; the attendance cameras no longer match '
                'you.',
          ),
          const LegalParagraph(
            'You keep every alternative way of checking in afterward, and there '
            'is no penalty for withdrawing.',
          ),
          const LegalParagraph(
            'We may suspend or end access for anyone who violates these Terms, '
            'or to protect members, the Church, or the app. On termination, the '
            'license granted to you ends; sections that by their nature should '
            'survive — intellectual property, disclaimers, and limitation of '
            'liability — continue to apply.',
          ),
        ]),
        LegalSection('Disclaimers', [
          const LegalParagraph(
            'The app and its identification system are provided "as is" and "as '
            'available," without warranties of any kind, express or implied, '
            'including implied warranties of merchantability, fitness for a '
            'particular purpose, and non-infringement, to the fullest extent '
            'permitted by law.',
          ),
          const LegalParagraph(
            'Performance may vary with environmental factors such as lighting, '
            'headwear, eyewear, camera position, and sudden technical '
            'disruptions. We do not warrant that the app will be uninterrupted, '
            'error-free, or secure, that attendance will always be recorded '
            'correctly, or that reminders will always be delivered. The Church '
            'is not liable for system outages, network failures, or technical '
            'errors that result in missed or incorrect attendance logging.',
          ),
          const LegalCallout(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'Scope of the identification features',
            text: "The app's facial recognition and NFC check-in exist for one "
                'purpose: recording attendance at participating church '
                'locations during authorized church activities. They are not '
                'identity-verification, security-screening, access-control, or '
                'background-check services, and we make no warranty that they '
                'are fit for any such use. The Church is not responsible for '
                'any use of the app, or reliance on its attendance records or '
                'identification results, outside that purpose or away from '
                'participating church locations — including use for identity '
                'verification, employment, licensing, safety screening, or any '
                'legal or evidentiary purpose. Attendance records are a '
                'convenience for church administration, not a certified record '
                "of anyone's presence, identity, or whereabouts.",
          ),
        ]),
        LegalSection('Limitation of liability', [
          LegalParagraph(
            'To the fullest extent permitted by law, $church and its pastors, '
            'staff, volunteers, and service providers will not be liable for any '
            'indirect, incidental, special, consequential, or punitive damages, '
            'or for lost data or lost profits, arising out of or relating to '
            'your use of the app. Nothing in these Terms limits liability that '
            'cannot be limited under applicable law, including under the '
            'any privacy or biometric-data law that applies to you.',
          ),
        ]),
        LegalSection('Changes to these Terms', [
          const LegalParagraph(
            'We may update these Terms from time to time. When we do, we will '
            'change the "Last updated" date above and, where appropriate, notify '
            'you in the app. Material changes to how we handle facial data will '
            'be made through the Privacy Policy and, where required by law, with '
            'your renewed consent. Continuing to use the app after an update '
            'means you accept the revised Terms.',
          ),
        ]),
        LegalSection('Governing law', [
          LegalParagraph(
            'These Terms are governed by the laws of the State of '
            '${LegalValues.governingState} and the United States, without regard '
            'to conflict-of-laws rules. Any dispute will be handled in the state '
            'or federal courts located in ${LegalValues.governingState}, unless '
            'applicable law requires otherwise.',
          ),
        ]),
        LegalSection('Contact us', [
          const LegalParagraph('Questions about these Terms? Reach us at:'),
          LegalContacts(email: LegalValues.supportEmail),
        ]),
      ],
    );
  }
}
