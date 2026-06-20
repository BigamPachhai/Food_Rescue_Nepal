import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _AppHeader(),
          const SizedBox(height: 24),
          const _Section('Mission', [
            _InfoTile(icon: Icons.eco_rounded, title: 'Our Mission', subtitle: 'Connecting surplus food vendors with conscious consumers to reduce food waste and hunger in Nepal.', iconColor: AppColors.primaryMedium),
          ]),
          const _Section('App Information', [
            _FutureVersionTile(),
            _InfoTile(icon: Icons.calendar_today_rounded, title: 'Released', subtitle: '2024'),
            _InfoTile(icon: Icons.update_rounded, title: 'Last Updated', subtitle: 'June 2025'),
            _InfoTile(icon: Icons.language_rounded, title: 'Available In', subtitle: 'English, नेपाली'),
          ]),
          _Section('Links', [
            _TappableTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () => context.push('/legal/privacy')),
            _TappableTile(icon: Icons.description_outlined, title: 'Terms of Service', onTap: () => context.push('/legal/terms')),
            _TappableTile(icon: Icons.help_outline_rounded, title: 'How It Works', onTap: () => context.push('/how-it-works')),
            _TappableTile(icon: Icons.star_rate_rounded, title: 'Rate the App', onTap: () {}),
            _TappableTile(icon: Icons.share_rounded, title: 'Share App', onTap: () {}),
          ]),
          _Section('Contact', [
            _TappableTile(icon: Icons.email_outlined, title: 'Contact Support', subtitle: 'support@foodrescuenepal.app', onTap: () => launchUrl(Uri.parse('mailto:support@foodrescuenepal.app'))),
            _TappableTile(icon: Icons.web_rounded, title: 'Website', subtitle: 'foodrescuenepal.app', onTap: () {}),
            _TappableTile(icon: Icons.people_outline_rounded, title: 'Join Our Community', onTap: () {}),
          ]),
          const _Section('Credits', [
            _InfoTile(icon: Icons.code_rounded, title: 'Built With', subtitle: 'Flutter & NestJS'),
            _InfoTile(icon: Icons.psychology_rounded, title: 'AI Powered By', subtitle: 'Mistral AI (Free Tier)'),
            _InfoTile(icon: Icons.map_rounded, title: 'Maps', subtitle: 'OpenStreetMap via flutter_map'),
            _InfoTile(icon: Icons.cloud_rounded, title: 'Backend', subtitle: 'NestJS + PostgreSQL + Prisma'),
          ]),
          const SizedBox(height: 24),
          Center(child: Column(children: [
            Text('Made with ❤️ for Nepal', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryMedium)),
            const SizedBox(height: 4),
            Text('© 2025 Food Rescue Nepal. All rights reserved.', style: AppTextStyles.caption),
          ])),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryMedium]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.eco_rounded, color: AppColors.primaryMedium, size: 48),
      ),
      const SizedBox(height: 14),
      Text('Food Rescue Nepal', style: AppTextStyles.h3OnPrimary),
      Text('Save Food. Save Money. Save Earth.', style: AppTextStyles.bodySmallOnPrimary),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
        child: const Text('🌱 Version 1.0.0', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

class _FutureVersionTile extends StatelessWidget {
  const _FutureVersionTile();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (_, snap) => _InfoTile(
      icon: Icons.info_outline_rounded,
      title: 'Version',
      subtitle: snap.hasData ? '${snap.data!.version} (${snap.data!.buildNumber})' : '1.0.0',
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: AppTextStyles.h5),
    const SizedBox(height: 8),
    Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: () {
        final items = <Widget>[];
        for (int i = 0; i < children.length; i++) {
          items.add(children[i]);
          if (i < children.length - 1) items.add(const Divider(height: 1, indent: 56));
        }
        return items;
      }()),
    ),
    const SizedBox(height: 16),
  ]);
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color? iconColor;
  const _InfoTile({required this.icon, required this.title, required this.subtitle, this.iconColor});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: (iconColor ?? AppColors.primaryMedium).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: iconColor ?? AppColors.primaryMedium, size: 20),
    ),
    title: Text(title, style: AppTextStyles.label),
    subtitle: Text(subtitle, style: AppTextStyles.caption),
  );
}

class _TappableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _TappableTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.primaryMedium.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: AppColors.primaryMedium, size: 20),
    ),
    title: Text(title, style: AppTextStyles.label),
    subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    onTap: onTap,
  );
}
