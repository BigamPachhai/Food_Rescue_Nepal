import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(_privacyPolicy, style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
      ),
    );
  }
}

const _privacyPolicy = '''
Last updated: January 2025

1. Information We Collect
We collect information you provide directly to us, including your name, email address, phone number, and location when you register for an account or use our services.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services, process transactions, send notifications about your orders, and communicate with you about promotions and updates.

3. Information Sharing
We do not sell or share your personal information with third parties except as necessary to provide our services (e.g., vendors fulfilling your orders) or as required by law.

4. Location Data
With your permission, we collect location data to show you nearby food listings. You can disable location access at any time through your device settings.

5. Data Security
We implement industry-standard security measures to protect your personal information. However, no method of transmission over the internet is 100% secure.

6. Data Retention
We retain your account information for as long as your account is active. You may request deletion of your data at any time by contacting us at privacy@foodrescuenepal.com.

7. Children's Privacy
Our service is not directed to children under 13. We do not knowingly collect personal information from children under 13.

8. Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

9. Contact Us
If you have any questions about this Privacy Policy, please contact us at privacy@foodrescuenepal.com.
''';
