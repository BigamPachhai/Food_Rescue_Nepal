import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final pendingVendorsAsync = ref.watch(adminVendorsProvider('PENDING'));
    final recentOrdersAsync = ref.watch(adminOrdersProvider(''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(adminVendorsProvider('PENDING'));
          ref.invalidate(adminOrdersProvider(''));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI grid
              statsAsync.when(
                data: (stats) => LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = Responsive.gridColumns(context, mobile: 2, tablet: 4);
                    return GridView.count(
                      crossAxisCount: cols,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: cols == 4 ? 1.6 : 1.4,
                      children: [
                        _KpiCard(
                          label: 'Total Users',
                          value: '${stats.totalUsers}',
                          icon: Icons.people_outline,
                          color: AppColors.info,
                        ),
                        _KpiCard(
                          label: 'Total Vendors',
                          value: '${stats.totalVendors}',
                          icon: Icons.store_outlined,
                          color: AppColors.accentAmber,
                        ),
                        _KpiCard(
                          label: 'Total Orders',
                          value: '${stats.totalOrders}',
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.primaryMedium,
                        ),
                        _KpiCard(
                          label: 'Revenue',
                          value: Formatters.formatNPR(stats.totalRevenuePaisa),
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                      ],
                    );
                  },
                ),
                loading: () => const ShimmerCard(height: 180),
                error: (e, _) => ErrorView(
                  error: e,
                  onRetry: () => ref.invalidate(adminStatsProvider),
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // Pending vendors
              Row(
                children: [
                  Text('Pending Vendors', style: AppTextStyles.h5),
                  const SizedBox(width: 8),
                  pendingVendorsAsync.maybeWhen(
                    data: (v) => v.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusPending,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${v.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/admin/vendors'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              pendingVendorsAsync.when(
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No pending vendors',
                          style: AppTextStyles.bodySmall),
                    );
                  }
                  return Column(
                    children: vendors
                        .take(3)
                        .map((v) => _VendorTile(
                              vendor: v,
                              onTap: () => context
                                  .push('/admin/vendors/${v.id}'),
                            ))
                        .toList(),
                  );
                },
                loading: () => const ShimmerCard(height: 60),
                error: (e, _) => _AdminInlineError(
                  message: 'Could not load pending vendors',
                  onRetry: () =>
                      ref.invalidate(adminVendorsProvider('PENDING')),
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // Recent orders
              Row(
                children: [
                  Text('Recent Orders', style: AppTextStyles.h5),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/admin/orders'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              recentOrdersAsync.when(
                data: (orders) => Column(
                  children: orders
                      .take(5)
                      .map((o) => _OrderTile(order: o))
                      .toList(),
                ),
                loading: () => const ShimmerCard(height: 60),
                error: (e, _) => _AdminInlineError(
                  message: 'Could not load recent orders',
                  onRetry: () => ref.invalidate(adminOrdersProvider('')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTextStyles.h4.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({required this.vendor, required this.onTap});
  final AdminVendor vendor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primarySurface,
        child: Icon(Icons.store, color: AppColors.primaryLight, size: 20),
      ),
      title: Text(vendor.businessName, style: AppTextStyles.h6),
      subtitle: Text(vendor.ownerEmail, style: AppTextStyles.caption),
      trailing: StatusBadge(status: vendor.status),
      onTap: onTap,
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.primarySurface,
        child: Icon(Icons.receipt_long, color: AppColors.primaryLight, size: 20),
      ),
      title: Text(
        order.listingName ?? 'Order #${order.id.substring(0, 6)}',
        style: AppTextStyles.h6,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(order.customerName ?? '', style: AppTextStyles.caption),
      trailing: SizedBox(
        width: 96,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(status: order.status, compact: true),
            const SizedBox(height: 2),
            Text(
              Formatters.formatNPR(order.totalAmount),
              style: AppTextStyles.caption.copyWith(color: AppColors.primaryMedium),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Inline error banner ───────────────────────────────────────────────────

class _AdminInlineError extends StatelessWidget {
  const _AdminInlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
