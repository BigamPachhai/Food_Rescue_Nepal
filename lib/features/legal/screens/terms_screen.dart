import 'package:flutter/material.dart';
import '../../../core/constants/app_text_styles.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(_termsConditions, style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
      ),
    );
  }
}

const _termsConditions = '''
Last updated: January 2025

1. Acceptance of Terms
By using Food Rescue Nepal, you agree to these Terms & Conditions. If you do not agree, please do not use our service.

2. User Accounts
You are responsible for maintaining the confidentiality of your account credentials. You must notify us immediately of any unauthorized use of your account.

3. Food Listings
Vendors are solely responsible for the accuracy of their food listings, including descriptions, pricing, and pickup times. Food Rescue Nepal does not guarantee the quality or safety of any listed food items.

4. Orders & Pickups
Orders are confirmed upon vendor acceptance. Customers must pick up their orders within the specified pickup window. Failure to pick up may result in order cancellation.

5. Payments
All payments are processed at pickup (cash on pickup). Food Rescue Nepal does not process online payments.

6. Cancellations
Customers may cancel orders within 10 minutes of placing them. After this window, cancellations are subject to vendor discretion.

7. Reviews
Users may leave reviews for completed orders. Reviews must be honest and based on genuine experience. Fake or abusive reviews will be removed.

8. Prohibited Conduct
You may not use our service to post false information, harass other users, or engage in any illegal activity.

9. Limitation of Liability
Food Rescue Nepal is not liable for any indirect, incidental, or consequential damages arising from your use of our service.

10. Governing Law
These terms are governed by the laws of Nepal. Any disputes shall be resolved in the courts of competent jurisdiction.

11. Contact
For questions about these terms, contact us at legal@foodrescuenepal.com.
''';
