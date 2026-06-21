import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, ref, user),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
                child: Padding(
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
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Impact & Rewards',
                    children: [
                      _ProfileTile(
                        icon: Icons.emoji_events_rounded,
                        iconColor: Colors.amber,
                        label: 'Achievements',
                        subtitle: 'Badges and milestones unlocked',
                        onTap: () => context.push('/customer/achievements'),
                      ),
                      _ProfileTile(
                        icon: Icons.stars_rounded,
                        iconColor: Colors.orange,
                        label: 'Loyalty Points',
                        subtitle: 'Your points balance and history',
                        onTap: () => context.push('/customer/loyalty'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Order Tools',
                    children: [
                      _ProfileTile(
                        icon: Icons.calendar_month_rounded,
                        iconColor: Colors.teal,
                        label: 'Pickup Calendar',
                        subtitle: 'View scheduled pickups by date',
                        onTap: () => context.push('/customer/orders/calendar'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Community',
                    children: [
                      _ProfileTile(
                        icon: Icons.flag_rounded,
                        iconColor: Colors.deepOrange,
                        label: 'Challenges',
                        subtitle: 'Weekly and monthly rescue challenges',
                        onTap: () => context.push('/customer/challenges'),
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
              if (user?.createdAt != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Member since ${Formatters.formatMonthYear(user!.createdAt!)}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _deleteAccountButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete account?'),
              content: const Text(
                'This will permanently delete your account and all associated data. This action cannot be undone.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true) ref.read(authProvider.notifier).deleteAccount();
        },
        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
        label: Text(
          'Delete Account',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Log out?'),
              content: const Text('You\'ll need to sign in again to access your account.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Log out'),
                ),
              ],
            ),
          );
          if (confirmed == true) ref.read(authProvider.notifier).logout();
        },
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

