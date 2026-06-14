import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, ref, user),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'Account',
                    children: [
                      _ProfileTile(
                        icon: Icons.person_outline,
                        label: 'Edit Profile',
                        subtitle: 'Name, phone, profile picture',
                        onTap: () => context.push('/customer/profile/edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Activity',
                    children: [
                      _ProfileTile(
                        icon: Icons.favorite_outline,
                        iconColor: AppColors.error,
                        label: 'My Favorites',
                        subtitle: 'Saved vendors and listings',
                        onTap: () => context.go('/customer/favorites'),
                      ),
                      _ProfileTile(
                        icon: Icons.receipt_long_outlined,
                        label: 'My Orders',
                        subtitle: 'View order history',
                        onTap: () => context.go('/customer/orders'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Preferences',
                    children: [
                      _ProfileTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () => context.push('/notifications'),
                      ),
                      _ProfileTile(
                        icon: Icons.language_outlined,
                        label: 'Language',
                        subtitle: 'English',
                        onTap: () => _showLanguageSheet(context),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Support',
                    children: [
                      _ProfileTile(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        subtitle: 'Contact us, FAQs',
                        onTap: () => context.push('/customer/support'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _logoutButton(context, ref),
                  const SizedBox(height: 12),
                  _deleteAccountButton(context, ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.avatarUrl != null
                        ? CachedNetworkImageProvider(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                            style: AppTextStyles.h2.copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => context.push('/customer/profile/edit'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primaryMedium),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? 'Customer', style: AppTextStyles.h3OnPrimary),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: AppTextStyles.bodySmallOnPrimary),
              if (user?.phone != null) ...[
                const SizedBox(height: 2),
                Text(user!.phone!, style: AppTextStyles.bodySmallOnPrimary),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout, color: AppColors.primaryMedium),
        label: Text('Logout', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _deleteAccountButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _confirmDeleteAccount(context, ref),
        child: Text(
          'Delete Account',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final dio = ref.read(dioClientProvider);
                await dio.delete('/users/account');
              } catch (_) {}
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.showSnackBar('Account deleted successfully.');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language', style: AppTextStyles.h5),
            const SizedBox(height: 16),
            _langOption(context, 'English', true),
            _langOption(context, 'नेपाली (Nepali)', false),
          ],
        ),
      ),
    );
  }

  Widget _langOption(BuildContext context, String label, bool selected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primaryMedium) : null,
      onTap: () => Navigator.pop(context),
    );
  }

}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.iconColor = AppColors.primaryMedium,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(label, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
          subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.caption) : null,
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        if (showDivider) const Divider(height: 1, indent: 72, endIndent: 16),
      ],
    );
  }
}
