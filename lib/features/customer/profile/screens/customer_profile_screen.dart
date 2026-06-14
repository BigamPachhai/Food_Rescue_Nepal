import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: user?.avatarUrl != null
                        ? NetworkImage(user!.avatarUrl!)
                        : null,
                    child: user?.avatarUrl == null
                        ? Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.h2
                                .copyWith(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '',
                      style: AppTextStyles.h3OnPrimary),
                  Text(user?.email ?? '',
                      style: AppTextStyles.bodySmallOnPrimary),
                  if (user?.phone != null)
                    Text(user!.phone!,
                        style: AppTextStyles.bodySmallOnPrimary),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                children: [
                  _ProfileTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () => context.push('/customer/profile/edit'),
                  ),
                  _ProfileTile(
                    icon: Icons.favorite_outline,
                    label: 'My Favorites',
                    onTap: () => context.go('/customer/favorites'),
                  ),
                  _ProfileTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => context.push('/notifications'),
                  ),
                  _ProfileTile(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => context.showSnackBar('Coming soon'),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                  AppButton(
                    label: 'Logout',
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        ref.read(authProvider.notifier).logout(),
                    icon: Icons.logout,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryMedium),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}
