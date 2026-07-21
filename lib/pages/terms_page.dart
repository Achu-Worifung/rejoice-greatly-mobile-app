import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../util/legal_config.dart';
import '../widgets/church_app_bar.dart';
import '../widgets/legal_document.dart';

/// Terms of Service for the Rejoice Greatly app.
///
/// Church-specific identity (legal name, contact, governing state, effective
/// date) comes from `.env` via [LegalConfig], so this text can ship unchanged
/// and be finalised through configuration. See `lib/util/legal_config.dart`.
///
/// This content is a good-faith, plain-language draft grounded in what the app
/// actually does. It is not legal advice; have counsel review it before
/// release, especially the biometric, arbitration, and liability sections.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = LegalConfig.appName;
    final entity = LegalConfig.legalEntity;
    final state = LegalConfig.governingState;

    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle('Terms of service'),
      body: LegalDocument(
        title: 'Terms of Service',
        effectiveDate: LegalConfig.effectiveDate,
        intro: [
          'Welcome to $app. These Terms of Service ("Terms") are an agreement '
              'between you and $entity ("we," "us," or "the Church") and govern '
              'your use of the $app mobile application and the features within '
              'it (together, the "App").',
          'Please read these Terms together with our Privacy Policy, which '
              'explains how we handle your information — including the facial '
              '(biometric) data used to record your attendance. By creating an '
              'account or using the App, you agree to both.',
        ],
        sections: [
          LegalSection(
            heading: 'Who can use the App',
            blocks: [
              const LegalParagraph(
                'The App is offered to members and friends of the congregation. '
                'It is intended for a general audience within church life, but '
                'accounts are for adults only.',
              ),
              const LegalBullet(
                'you are 18 years of age or older;',
                lead: 'You confirm that:',
              ),
              const LegalBullet(
                'the information you give us at sign-up is true and belongs to '
                'you; and',
              ),
              const LegalBullet(
                'you will keep your account credentials confidential and are '
                'responsible for activity that happens under your account.',
              ),
              const LegalParagraph(
                'The App is not directed to, and may not be used by, anyone '
                'under 18. We do not knowingly create accounts for, or collect '
                'facial data from, minors. If you believe a minor has created '
                'an account, contact us and we will remove it.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Your account and sign-in',
            blocks: [
              const LegalParagraph(
                'You can create an account with your email and a password, or '
                'by using Sign in with Google or Sign in with Apple. Sign-in is '
                'handled through Google Firebase Authentication. You are '
                'responsible for maintaining the security of the email account '
                'or provider you use to sign in.',
              ),
              const LegalParagraph(
                'Completing sign-up includes a one-time enrollment step in which '
                'the App uses your device camera to capture several photos of '
                'your face. This is required to use facial-recognition '
                'attendance. Your consent to that processing is described in '
                'the Privacy Policy, and you may withdraw it as explained there.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Attendance and facial recognition',
            blocks: [
              const LegalParagraph(
                'A core purpose of the App is to record your attendance at '
                'church services using facial recognition. During enrollment, '
                'the App captures images of your face; the Church converts these '
                'into a mathematical representation (a "face embedding") used to '
                'recognize you.',
              ),
              const LegalParagraph(
                'On service days, cameras operated by the Church at its premises '
                'match faces against enrolled members and mark recognized '
                'members present. Attendance is recorded by facial recognition; '
                'the App does not use Bluetooth-based check-in.',
              ),
              const LegalBullet(
                'Recognition is not perfect. Lighting, pose, camera position, '
                'and appearance changes can cause a missed or incorrect match. '
                'Attendance records are a convenience and may contain errors — '
                'contact the Church to correct your record.',
                lead: 'Please understand:',
              ),
              const LegalBullet(
                'Enrollment and attendance features depend on Church-operated '
                'equipment and on-site cameras that may not always be available.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Sermons, events, reminders, and content',
            blocks: [
              const LegalParagraph(
                'The App lets you play sermons and audio, browse and get '
                'reminders about events, view a weekly verse, track attendance '
                'streaks, and access community features. Content in the App '
                '(sermons, media, event details, verses, and text) is provided '
                'for your personal, non-commercial use and remains the property '
                'of the Church or its licensors.',
              ),
              const LegalParagraph(
                'With your permission, the App sends push notifications and '
                'email reminders (for example, about upcoming events or a '
                'service you may have missed). You can turn notifications off in '
                'your device settings at any time; some reminders may also be '
                'managed within the App.',
              ),
            ],
          ),
          LegalSection(
            heading: 'The Mood Changing Café',
            blocks: [
              const LegalParagraph(
                'The App includes a café/community area that opens the Mood '
                'Changing Café, a connected web experience. When you are signed '
                'in, the App can pass your sign-in securely into the café so you '
                'do not have to log in again. The café is a separate service '
                'with its own features (such as ordering and order history) and '
                'may have its own terms. Your use of the café is subject to '
                'those terms in addition to these.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Acceptable use',
            blocks: [
              const LegalParagraph('You agree not to:'),
              const LegalBullet(
                'impersonate another person, or enroll or attempt to recognize '
                'anyone other than yourself;',
              ),
              const LegalBullet(
                'attempt to access accounts, attendance records, or Church '
                'systems that are not yours, including admin or moderation '
                'tools;',
              ),
              const LegalBullet(
                'interfere with, disrupt, probe, or reverse engineer the App or '
                'its security, or use it to build a competing facial-recognition '
                'dataset;',
              ),
              const LegalBullet(
                'upload unlawful, harmful, or infringing content, or use the App '
                'in a way that violates any law or the rights of others.',
              ),
              const LegalParagraph(
                'Some features (such as content moderation and administration) '
                'are available only to authorized Church staff and volunteers.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Suspension and termination',
            blocks: [
              const LegalParagraph(
                'You may stop using the App and delete your account at any time. '
                'To delete your account and your enrolled facial data, use the '
                'in-app option where available or contact the Church (see '
                '"Contact us"). We may suspend or end your access if you violate '
                'these Terms, or to protect members, the Church, or the App. On '
                'termination, the license granted to you ends; sections that by '
                'their nature should survive (such as intellectual property, '
                'disclaimers, and limitation of liability) continue to apply.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Disclaimers',
            blocks: [
              const LegalParagraph(
                'The App is provided "as is" and "as available," without '
                'warranties of any kind, whether express or implied, including '
                'implied warranties of merchantability, fitness for a particular '
                'purpose, and non-infringement, to the fullest extent permitted '
                'by law. We do not warrant that the App will be uninterrupted, '
                'error-free, or secure, that attendance will always be recorded '
                'correctly, or that reminders will always be delivered.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Limitation of liability',
            blocks: [
              LegalParagraph(
                'To the fullest extent permitted by law, $entity and its '
                'pastors, staff, volunteers, and service providers will not be '
                'liable for any indirect, incidental, special, consequential, or '
                'punitive damages, or for lost data or lost profits, arising out '
                'of or relating to your use of the App. Nothing in these Terms '
                'limits liability that cannot be limited under applicable law, '
                'including under the biometric-privacy laws described in the '
                'Privacy Policy.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Changes to these Terms',
            blocks: [
              const LegalParagraph(
                'We may update these Terms from time to time. When we do, we '
                'will change the "Last updated" date above and, where '
                'appropriate, notify you in the App. Material changes to how we '
                'handle facial data will be made through the Privacy Policy and, '
                'where required by law, with your renewed consent. Continuing to '
                'use the App after an update means you accept the revised Terms.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Governing law',
            blocks: [
              LegalParagraph(
                'These Terms are governed by the laws of the State of $state and '
                'the United States, without regard to conflict-of-laws rules. '
                'Any dispute will be handled in the state or federal courts '
                'located in $state, unless applicable law requires otherwise.',
              ),
            ],
          ),
          LegalSection(
            heading: 'Contact us',
            blocks: [
              LegalParagraph(
                'Questions about these Terms? Reach us at '
                '${LegalConfig.supportEmail}, or by mail at '
                '${LegalConfig.mailingAddress}.',
              ),
            ],
          ),
        ],
        footer: [
          LegalParagraph(
            'These Terms work alongside the $app Privacy Policy, which explains '
            'in detail how your facial data and other information are collected, '
            'used, protected, retained, and deleted.',
          ),
        ],
      ),
    );
  }
}
