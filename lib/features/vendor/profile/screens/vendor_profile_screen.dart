import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/vendor_profile_provider.dart';

class VendorProfileScreen extends ConsumerWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final profileAsync = ref.watch(vendorProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async => ref.invalidate(vendorProfileProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              profileAsync.when(
                data: (vendor) => _buildHeader(context, user, vendor),
                loading: () => _buildHeader(context, user, null),
                error: (_, __) => _buildHeader(context, user, null),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Column(
                  children: [
                    profileAsync.when(
                      data: (vendor) => _buildInfoCard(vendor),
                      loading: () => const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryMedium)),
                      ),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Store Management',
                      children: [
                        _ProfileTile(
                          icon: Icons.edit_outlined,
                          label: 'Edit Store Profile',
                          subtitle: 'Name, description, location',
                          onTap: () async {
                            await context.push('/vendor/profile/edit');
                            ref.invalidate(vendorProfileProvider);
                          },
                        ),
                        _ProfileTile(
                          icon: Icons.qr_code_scanner,
                          label: 'Scan Customer QR',
                          subtitle: 'Verify order pickup',
                          onTap: () => context.push('/vendor/scanner'),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Settings',
                      children: [
                        _ProfileTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          subtitle: 'Manage order alerts',
                          onTap: () => context.push('/notifications'),
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
                          subtitle: 'Contact us',
                          onTap: () => _showHelpDialog(context),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _logoutButton(context, ref),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, user, VendorProfile? vendor) {
    final statusColor = _statusColor(vendor?.status);
    final statusLabel = _statusLabel(vendor?.status);

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
                    backgroundImage: vendor?.logoUrl != null
                        ? CachedNetworkImageProvider(vendor!.logoUrl!)
                        : null,
                    child: vendor?.logoUrl == null
                        ? const Icon(Icons.store, size: 40, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => context.push('/vendor/profile/edit'),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primaryMedium),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(vendor?.businessName ?? user?.name ?? 'My Store', style: AppTextStyles.h3OnPrimary),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: AppTextStyles.bodySmallOnPrimary),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(VendorProfile vendor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Info', style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          if (vendor.description != null && vendor.description!.isNotEmpty) ...[
            Text(vendor.description!, style: AppTextStyles.bodySmall),
            const SizedBox(height: 12),
          ],
          _InfoRow(icon: Icons.store_outlined, text: vendor.businessType),
          _InfoRow(icon: Icons.location_on_outlined, text: vendor.address),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.accentAmber),
              const SizedBox(width: 6),
              Text(
                '${vendor.avgRating.toStringAsFixed(1)} (${vendor.totalReviews} reviews)',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => ref.read(authProvider.notifier).logout(),
        icon: const Icon(Icons.logout, color: AppColors.primaryMedium),
        label: Text(
          'Logout',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.primaryMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.email_outlined, size: 16), SizedBox(width: 8), Text('support@foodrescuenepal.com')]),
            SizedBox(height: 8),
            Row(children: [Icon(Icons.phone_outlined, size: 16), SizedBox(width: 8), Text('+977-01-5555000')]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    return switch (status) {
      'APPROVED' => AppColors.success,
      'PENDING' => AppColors.warning,
      'SUSPENDED' => AppColors.error,
      _ => AppColors.warning,
    };
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'APPROVED' => 'Active',
      'PENDING' => 'Pending Approval',
      'SUSPENDED' => 'Suspended',
      _ => 'Pending',
    };
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
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
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    const iconColor = AppColors.primaryMedium;
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
