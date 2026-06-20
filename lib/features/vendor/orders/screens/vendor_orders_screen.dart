import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/vendor_orders_provider.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _activeFilter = 'All';

  static const _activeFilters = ['All', 'Pending', 'Accepted', 'Ready'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(vendorOrdersProvider);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan QR',
            onPressed: () => context.push('/vendor/scanner'),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          onTap: (_) => setState(() => _activeFilter = 'All'),
          tabs: ordersAsync.when(
            data: (orders) {
              final pendingCount = orders.where((o) => o.status == 'PENDING').length;
              return [
                Tab(text: pendingCount > 0 ? 'Active ($pendingCount)' : 'Active'),
                const Tab(text: 'History'),
              ];
            },
            loading: () => const [Tab(text: 'Active'), Tab(text: 'History')],
            error: (_, __) => const [Tab(text: 'Active'), Tab(text: 'History')],
          ),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          final active = orders
              .where((o) => o.status == 'PENDING' || o.status == 'ACCEPTED' || o.status == 'READY')
              .toList();
          final history = orders
              .where((o) =>
                  o.status == 'COMPLETED' ||
                  o.status == 'CANCELLED' ||
                  o.status == 'REJECTED' ||
                  o.status == 'EXPIRED')
              .toList();

          // Today's revenue from completed orders
          final today = DateTime.now();
          final todayRevenue = history
              .where((o) =>
                  o.status == 'COMPLETED' &&
                  o.updatedAt.year == today.year &&
                  o.updatedAt.month == today.month &&
                  o.updatedAt.day == today.day)
              .fold<int>(0, (sum, o) => sum + o.totalAmount);

          return TabBarView(
            controller: _tabCtrl,
            children: [
              Column(
                children: [
                  // Filter chips for active orders
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _activeFilters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final f = _activeFilters[i];
                        final sel = f == _activeFilter;
                        final count = f == 'All'
                            ? active.length
                            : active.where((o) => o.status == f.toUpperCase()).length;
                        return FilterChip(
                          label: Text('$f ($count)'),
                          selected: sel,
                          onSelected: (_) => setState(() => _activeFilter = f),
                          selectedColor: AppColors.primaryMedium,
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 12,
                          ),
                          showCheckmark: false,
                          side: BorderSide(
                            color: sel ? AppColors.primaryMedium : AppColors.neutral300,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _ReservationList(
                      reservations: _activeFilter == 'All'
                          ? active
                          : active.where((o) => o.status == _activeFilter.toUpperCase()).toList(),
                      isActive: true,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  if (todayRevenue > 0)
                    Container(
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryMedium],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.payments_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Today's revenue: ${Formatters.formatNPR(todayRevenue)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: _ReservationList(reservations: history, isActive: false)),
                ],
              ),
            ],
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSizes.s4),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.s2),
            child: ShimmerCard(height: 88),
          ),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.read(vendorOrdersProvider.notifier).fetch(),
        ),
      ),
    );
  }
}

class _ReservationList extends ConsumerWidget {
  const _ReservationList({required this.reservations, required this.isActive});
  final List<VendorOrder> reservations;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservations.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryMedium,
        onRefresh: () => ref.read(vendorOrdersProvider.notifier).fetch(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyStateView(
              icon: isActive ? Icons.pending_actions_outlined : Icons.receipt_long_outlined,
              title: isActive ? 'No active reservations' : 'No reservation history',
              subtitle: isActive
                  ? 'Pull down to refresh. New customer reservations appear here.'
                  : 'Completed, cancelled and rejected reservations appear here.',
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.primaryMedium,
      onRefresh: () => ref.read(vendorOrdersProvider.notifier).fetch(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSizes.s4, AppSizes.s3, AppSizes.s4, AppSizes.s4),
        itemCount: reservations.length,
        itemBuilder: (_, i) => _VendorOrderCard(order: reservations[i]),
      ),
    );
  }
}

class _VendorOrderCard extends ConsumerWidget {
  const _VendorOrderCard({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = order.status == 'PENDING';
    final timeAgo = Formatters.timeAgo(order.createdAt);

    return GestureDetector(
      onTap: () => context.push('/vendor/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.s2),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          boxShadow: AppShadows.card,
          border: isPending
              ? Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.s3),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isPending
                          ? AppColors.warningSurface
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      isPending
                          ? Icons.schedule_rounded
                          : Icons.receipt_long_rounded,
                      color: isPending
                          ? AppColors.accentAmber
                          : AppColors.primaryLight,
                      size: AppSizes.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSizes.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.listing?.name ?? 'Reservation #${order.id.substring(0, 6)}',
                          style: AppTextStyles.h6,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('×${order.quantity}', style: AppTextStyles.caption),
                            const SizedBox(width: 6),
                            const Text('·', style: TextStyle(color: AppColors.textTertiary)),
                            const SizedBox(width: 6),
                            Text(timeAgo, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(status: order.status, compact: true),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.formatNPR(order.totalAmount),
                        style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400, size: 18),
                ],
              ),
            ),
            // Inline accept/reject for PENDING orders
            if (isPending)
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.neutral100)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(vendorOrdersProvider.notifier).rejectReservation(order.id);
                          if (context.mounted) context.showSnackBar('Reservation rejected');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text('Reject', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await ref.read(vendorOrdersProvider.notifier).acceptOrder(order.id);
                          if (context.mounted) context.showSnackBar('Reservation accepted!');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMedium,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        child: const Text('Accept', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
