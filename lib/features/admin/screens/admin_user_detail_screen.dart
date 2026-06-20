import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../providers/admin_provider.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() =>
      _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState
    extends ConsumerState<AdminUserDetailScreen> {
  bool _isActing = false;

  Future<void> _toggleBan(bool currentlyActive) async {
    if (currentlyActive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ban User'),
          content: const Text('This will block the user from accessing the app. Are you sure?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Ban'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _isActing = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch(ApiEndpoints.adminBanUser(widget.userId));
      if (mounted) {
        context.showSnackBar(
            currentlyActive ? 'User banned' : 'User unbanned');
        ref.invalidate(adminUserDetailProvider(widget.userId));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isActing = false);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(adminUserDetailProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              // Avatar
              CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: AppTextStyles.h1
                      .copyWith(color: AppColors.primaryMedium),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: AppTextStyles.h3),
              Text(user.email, style: AppTextStyles.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _InfoChip(label: user.role),
                  const SizedBox(width: 8),
                  _InfoChip(
                    label: user.isActive ? 'Active' : 'Banned',
                    color: user.isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xxl),
              _InfoRow('User ID', user.id),
              _InfoRow('Joined', Formatters.formatDate(user.createdAt)),
              _InfoRow('Role', user.role),
              const SizedBox(height: AppSizes.xxl),
              if (user.role != 'ADMIN')
                AppButton(
                  label: user.isActive ? 'Ban User' : 'Unban User',
                  onPressed: _isActing
                      ? null
                      : () => _toggleBan(user.isActive),
                  isLoading: _isActing,
                  variant: user.isActive
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                ),
            ],
          ),
        ),
        loading: () => const ShimmerAdminDetail(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(adminUserDetailProvider(widget.userId)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Text(value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.color = AppColors.primaryMedium});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
