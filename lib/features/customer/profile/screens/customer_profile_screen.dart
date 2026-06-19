import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
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
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        subtitle: 'Theme, language, notifications',
                        onTap: () => context.push('/settings'),
                      ),
                      _ProfileTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () => context.push('/notifications'),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Community',
                    children: [
                      _ProfileTile(
                        icon: Icons.people_outline_rounded,
                        iconColor: AppColors.success,
                        label: 'Refer a Friend',
                        subtitle: 'Invite friends to rescue food together',
                        onTap: () {
                          Share.share(
                            '🌿 Join me on Food Rescue Nepal! Get discounted food and help reduce food waste across Nepal. Download the app now!',
                            subject: 'Join Food Rescue Nepal',
                          );
                        },
                      ),
                      _ProfileTile(
                        icon: Icons.leaderboard_outlined,
                        iconColor: AppColors.accentAmber,
                        label: 'Impact Leaderboard',
                        subtitle: 'See top food rescuers in your area',
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Coming Soon'),
                              content: const Text('The Impact Leaderboard is under development and will be available in a future update.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Got it'),
                                ),
                              ],
                            ),
                          );
                        },
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Support',
                    children: [
                      _ProfileTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.primaryMedium,
                        label: 'How It Works',
                        subtitle: 'Learn how to reserve and pick up',
                        onTap: () => context.push('/how-it-works'),
                      ),
                      _ProfileTile(
                        icon: Icons.support_agent_outlined,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeleteAccountSheet(
        onConfirmed: () async {
          try {
            final dio = ref.read(dioClientProvider);
            await dio.delete(ApiEndpoints.deleteAccount);
          } catch (_) {}
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) {
            context.go('/login');
            context.showSnackBar('Your account has been deleted.');
          }
        },
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

// ─── Multi-step account deletion sheet ────────────────────────────────────

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({required this.onConfirmed});
  final Future<void> Function() onConfirmed;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
  int _step = 0;
  final _controller = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canConfirm => _controller.text.trim() == 'DELETE';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 0 ? _buildStep1() : _buildStep2(),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Delete Account',
                style: AppTextStyles.h3.copyWith(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 16),
        Text('This will permanently delete:',
            style: AppTextStyles.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...[
          'Your profile and personal information',
          'All reservation history',
          'Your saved favorites',
          'Any pending reservations',
        ].map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.remove_circle_outline_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(item, style: AppTextStyles.bodySmall)),
                ],
              ),
            )),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Keep my account',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Confirm deletion',
            style: AppTextStyles.h4.copyWith(color: AppColors.error)),
        const SizedBox(height: 8),
        Text(
          'Type DELETE in the box below to confirm you want to permanently remove your account.',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Type DELETE here',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canConfirm && !_isDeleting
                ? () async {
                    setState(() => _isDeleting = true);
                    Navigator.pop(context);
                    await widget.onConfirmed();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              disabledBackgroundColor:
                  AppColors.error.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isDeleting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Delete My Account',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: Text('Go back',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ),
      ],
    );
  }
}
