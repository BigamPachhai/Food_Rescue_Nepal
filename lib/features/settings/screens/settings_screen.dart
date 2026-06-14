import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final notifPrefs = ref.watch(notifPrefsProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          const _SectionHeader('Appearance'),
          _Card(children: [
            const _TileLabel('Theme'),
            const SizedBox(height: 10),
            Row(
              children: [
                _ThemeChip(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  selected: themeMode == ThemeMode.light,
                  onTap: () =>
                      ref.read(themeProvider.notifier).set(ThemeMode.light),
                ),
                const SizedBox(width: 10),
                _ThemeChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  selected: themeMode == ThemeMode.dark,
                  onTap: () =>
                      ref.read(themeProvider.notifier).set(ThemeMode.dark),
                ),
                const SizedBox(width: 10),
                _ThemeChip(
                  label: 'System',
                  icon: Icons.brightness_auto_outlined,
                  selected: themeMode == ThemeMode.system,
                  onTap: () =>
                      ref.read(themeProvider.notifier).set(ThemeMode.system),
                ),
              ],
            ),
          ]),

          // ── Language ────────────────────────────────────────────────────
          const _SectionHeader('Language'),
          _Card(children: [
            _LanguageTile(
              label: 'English',
              subtitle: 'English',
              code: 'en',
              current: language,
              onTap: () => ref.read(languageProvider.notifier).set('en'),
            ),
            const Divider(height: 1),
            _LanguageTile(
              label: 'नेपाली',
              subtitle: 'Nepali',
              code: 'ne',
              current: language,
              onTap: () => ref.read(languageProvider.notifier).set('ne'),
            ),
          ]),

          // ── Notifications ───────────────────────────────────────────────
          const _SectionHeader('Notifications'),
          _Card(children: [
            _NotifToggle(
              label: 'Order Updates',
              subtitle: 'Confirmed, ready, and pickup alerts',
              prefKey: 'order_updates',
              prefs: notifPrefs,
              ref: ref,
            ),
            const Divider(height: 1),
            _NotifToggle(
              label: 'Nearby Food',
              subtitle: 'New listings near your location',
              prefKey: 'nearby_food',
              prefs: notifPrefs,
              ref: ref,
            ),
            const Divider(height: 1),
            _NotifToggle(
              label: 'Pickup Reminders',
              subtitle: 'Reminders before your pickup window closes',
              prefKey: 'pickup_reminders',
              prefs: notifPrefs,
              ref: ref,
            ),
            const Divider(height: 1),
            _NotifToggle(
              label: 'Promotions',
              subtitle: 'Special offers and featured deals',
              prefKey: 'promotions',
              prefs: notifPrefs,
              ref: ref,
            ),
          ]),

          // ── Legal ───────────────────────────────────────────────────────
          const _SectionHeader('Legal'),
          _Card(children: [
            _NavTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showLegal(context, 'Privacy Policy', _privacyPolicy),
            ),
            const Divider(height: 1),
            _NavTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () =>
                  _showLegal(context, 'Terms & Conditions', _termsConditions),
            ),
          ]),

          // ── About ───────────────────────────────────────────────────────
          const _SectionHeader('About'),
          _Card(children: [
            _NavTile(
              icon: Icons.info_outline,
              label: 'About Food Rescue Nepal',
              onTap: () => _showAbout(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.build_outlined,
                  color: AppColors.textSecondary),
              title: const Text('App Version'),
              trailing: Text('1.0.0',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showLegal(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LegalScreen(title: title, content: content),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _AboutScreen()),
    );
  }
}

// ─── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Card wrapper ──────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _TileLabel extends StatelessWidget {
  const _TileLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Text(text, style: AppTextStyles.bodyMedium),
    );
  }
}

// ─── Theme chip ────────────────────────────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primarySurface
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primaryMedium
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primaryMedium
                      : AppColors.textSecondary,
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? AppColors.primaryMedium
                        : AppColors.textSecondary,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language tile ─────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.code,
    required this.current,
    required this.onTap,
  });
  final String label;
  final String subtitle;
  final String code;
  final String current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = current == code;
    return ListTile(
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primaryMedium)
          : const Icon(Icons.radio_button_unchecked,
              color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ─── Notification toggle ───────────────────────────────────────────────────

class _NotifToggle extends StatelessWidget {
  const _NotifToggle({
    required this.label,
    required this.subtitle,
    required this.prefKey,
    required this.prefs,
    required this.ref,
  });
  final String label;
  final String subtitle;
  final String prefKey;
  final Map<String, bool> prefs;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final enabled = prefs[prefKey] ?? true;
    return SwitchListTile(
      value: enabled,
      onChanged: (_) => ref.read(notifPrefsProvider.notifier).toggle(prefKey),
      activeThumbColor: AppColors.primaryMedium,
      activeTrackColor: AppColors.primarySurface,
      title: Text(label, style: AppTextStyles.bodyMedium),
      subtitle: Text(subtitle, style: AppTextStyles.caption),
    );
  }
}

// ─── Nav tile ──────────────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ─── Legal screen ──────────────────────────────────────────────────────────

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(content,
            style: AppTextStyles.bodySmall.copyWith(height: 1.7)),
      ),
    );
  }
}

// ─── About screen ──────────────────────────────────────────────────────────

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.eco_rounded,
                  size: 52, color: AppColors.primaryMedium),
            ),
            const SizedBox(height: 16),
            Text('Food Rescue Nepal', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Version 1.0.0',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Text(
              'Food Rescue Nepal connects surplus food vendors with customers '
              'to reduce food waste across Nepal. By rescuing food that would '
              'otherwise go to waste, we help vendors recover costs while giving '
              'customers access to quality food at discounted prices.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const _AboutRow(Icons.email_outlined, 'support@foodrescuenepal.com'),
            const _AboutRow(Icons.language_outlined, 'www.foodrescuenepal.com'),
            const _AboutRow(Icons.location_on_outlined, 'Kathmandu, Nepal'),
            const SizedBox(height: 32),
            Text(
              '© 2025 Food Rescue Nepal. All rights reserved.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryMedium),
          const SizedBox(width: 10),
          Text(text, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ─── Static legal content ──────────────────────────────────────────────────

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
We retain your account information for as long as your account is active. You may request deletion of your data at any time by contacting us.

7. Children's Privacy
Our service is not directed to children under 13. We do not knowingly collect personal information from children under 13.

8. Changes to This Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

9. Contact Us
If you have any questions about this Privacy Policy, please contact us at privacy@foodrescuenepal.com.
''';

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
These terms are governed by the laws of Nepal. Any disputes shall be resolved in the courts of Kathmandu.

11. Contact
For questions about these terms, contact us at legal@foodrescuenepal.com.
''';
