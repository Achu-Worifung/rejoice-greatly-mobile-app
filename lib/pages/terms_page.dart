import 'package:flutter/material.dart';

import '../theme/church_colors.dart';
import '../widgets/church_app_bar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChurchColors.background,
      appBar: ChurchAppBar.pageTitle('Terms of service'),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Your terms of service content goes here.',
          style: TextStyle(
            color: ChurchColors.bodyText,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
