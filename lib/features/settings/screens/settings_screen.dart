import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
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
    final versionAsync = ref.watch(appVersionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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

          // ── Dietary Preferences ─────────────────────────────────────────
          const _SectionHeader('Dietary Preferences'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter listings by dietary needs', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Vegan', 'Vegetarian', 'Halal', 'Gluten Free', 'Dairy Free', 'Organic']
                        .map((tag) => _DietaryChip(label: tag))
                        .toList(),
                  ),
                ],
              ),
            ),
          ]),

          // ── Discovery ───────────────────────────────────────────────────
          const _SectionHeader('Discovery'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nearby Alert Radius', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Get alerts for new listings within this distance', style: AppTextStyles.caption),
                  const SizedBox(height: 8),
                  const _RadiusSlider(),
                ],
              ),
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

          // ── Account ─────────────────────────────────────────────────────
          const _SectionHeader('Account'),
          _Card(children: [
            _NavTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => context.push('/forgot-password'),
            ),
          ]),

          // ── Legal ───────────────────────────────────────────────────────
          const _SectionHeader('Legal'),
          _Card(children: [
            _NavTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => context.push('/legal/privacy'),
            ),
            const Divider(height: 1),
            _NavTile(
              icon: Icons.description_outlined,
              label: 'Terms & Conditions',
              onTap: () => context.push('/legal/terms'),
            ),
          ]),

          // ── Storage ─────────────────────────────────────────────────────
          const _SectionHeader('Storage'),
          _Card(children: [
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined,
                  color: AppColors.textSecondary),
              title: const Text('Clear Image Cache'),
              subtitle: const Text('Frees up cached images on device'),
              trailing: TextButton(
                onPressed: () {
                  PaintingBinding.instance.imageCache.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image cache cleared')),
                  );
                },
                child: const Text('Clear'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // ── About ───────────────────────────────────────────────────────
          const _SectionHeader('About'),
          _Card(children: [
            _NavTile(
              icon: Icons.help_outline_rounded,
              label: 'How It Works',
              onTap: () => context.push('/how-it-works'),
            ),
            const Divider(height: 1),
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
              trailing: Text(
                versionAsync.when(
                  data: (v) => v,
                  loading: () => '—',
                  error: (_, __) => '—',
                ),
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
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

// ─── About screen ──────────────────────────────────────────────────────────

class _AboutScreen extends ConsumerWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).maybeWhen(data: (v) => v, orElse: () => '—');
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SvgPicture.asset('assets/images/logo.svg'),
              ),
            ),
            const SizedBox(height: 16),
            Text('Food Rescue Nepal', style: AppTextStyles.h3),
            const SizedBox(height: 4),
            Text('Version $version',
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

// ─── Dietary chip (local UI state — persisting to prefs is a future step) ──

class _DietaryChip extends ConsumerWidget {
  const _DietaryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(dietaryPrefsProvider).contains(label);
    return GestureDetector(
      onTap: () => ref.read(dietaryPrefsProvider.notifier).toggle(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMedium : AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryMedium : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─── Nearby radius slider ───────────────────────────────────────────────────

class _RadiusSlider extends ConsumerWidget {
  const _RadiusSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radius = ref.watch(nearbyRadiusProvider);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
            Text(
              radius >= 50 ? 'Any distance' : '${radius.toInt()} km',
              style: AppTextStyles.label.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w700),
            ),
            Text('50 km', style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary)),
          ],
        ),
        Slider(
          value: radius,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: AppColors.primaryMedium,
          inactiveColor: AppColors.primarySurface,
          onChanged: (v) => ref.read(nearbyRadiusProvider.notifier).set(v),
        ),
      ],
    );
  }
}

