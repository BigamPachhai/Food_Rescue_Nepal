import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../providers/customer_orders_provider.dart';
import '../../../reviews/providers/reviews_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: const Text('Cancel Reservation?'),
        content: const Text(
          'Your reservation will be released and the slot returned to the vendor. You can always reserve again if it\'s still available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await ref
          .read(dioClientProvider)
          .patch(ApiEndpoints.orderCancel(widget.orderId));
      if (!mounted) return;
      context.showSnackBar('Reservation cancelled');
      ref.invalidate(orderDetailProvider(widget.orderId));
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Reservation Details')),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTimeline(order),
              const SizedBox(height: AppSizes.s4),
              if (order.listing != null) ...[
                const _SectionLabel(label: 'Item'),
                const SizedBox(height: AppSizes.s2),
                _ItemCard(order: order),
              ],
              const SizedBox(height: AppSizes.s4),
              if (order.vendor != null) ...[
                const _SectionLabel(label: 'Vendor'),
                const SizedBox(height: AppSizes.s2),
                _VendorCard(vendor: order.vendor!),
              ],
              const SizedBox(height: AppSizes.s4),
              const _SectionLabel(label: 'Reservation Info'),
              const SizedBox(height: AppSizes.s2),
              _InfoCard(
                rows: [
                  _InfoRowData('Reservation ID',
                      '#${order.id.substring(0, 8).toUpperCase()}'),
                  _InfoRowData('Placed at',
                      Formatters.formatDateTime(order.createdAt)),
                  _InfoRowData(
                      'Total', Formatters.formatNPR(order.totalAmount)),
                  const _InfoRowData('Payment', 'Cash on Pickup'),
                ],
              ),
              const SizedBox(height: AppSizes.s5),
              if (order.canShowQr)
                AppButton(
                  label: 'Show QR Code',
                  onPressed: () =>
                      context.push('/customer/orders/${order.id}/qr'),
                  icon: Icons.qr_code_2_rounded,
                ),
              if (order.canCancel) ...[
                const SizedBox(height: AppSizes.s2),
                AppButton(
                  label: 'Cancel Reservation',
                  onPressed: _isCancelling ? null : _cancelOrder,
                  isLoading: _isCancelling,
                  variant: AppButtonVariant.secondary,
                ),
              ],
              if (order.status == 'COMPLETED') ...[
                const SizedBox(height: AppSizes.s2),
                _ReviewButton(order: order),
              ],
              const SizedBox(height: AppSizes.s4),
            ],
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSizes.s4),
          child: ShimmerOrderDetail(),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(OrderEntity order) {
    final currentStatus = order.status;
    const steps = ['PENDING', 'ACCEPTED', 'READY', 'COMPLETED'];
    const labels = ['Placed', 'Accepted', 'Ready', 'Picked Up'];
    final timestamps = [
      order.createdAt,
      order.acceptedAt,
      order.readyAt,
      order.completedAt,
    ];
    final currentIndex = steps.indexOf(currentStatus);
    final isCancelled = currentStatus == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Status', style: AppTextStyles.h4),
              const Spacer(),
              if (isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s2, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(
                    'Cancelled',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.s4),
          if (isCancelled)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_rounded,
                    color: AppColors.error, size: 40),
                const SizedBox(width: AppSizes.s3),
                Text(
                  'This reservation\nwas cancelled',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            )
          else
            Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIndex = i ~/ 2;
                  final isDone = stepIndex < currentIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primaryMedium
                            : AppColors.neutral100,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  );
                }
                final stepIndex = i ~/ 2;
                final isDone = stepIndex < currentIndex;
                final isCurrent = stepIndex == currentIndex;
                return Column(
                  children: [
                    isCurrent
                        ? AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (_, child) => Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            ),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.primaryMedium,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryLight, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryMedium
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.circle,
                                  size: 8, color: Colors.white),
                            ),
                          )
                        : Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.primaryMedium
                                  : AppColors.neutral100,
                              shape: BoxShape.circle,
                            ),
                            child: isDone
                                ? const Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                    const SizedBox(height: AppSizes.s1),
                    Text(
                      labels[stepIndex],
                      style: AppTextStyles.caption.copyWith(
                        color: isDone || isCurrent
                            ? AppColors.primaryMedium
                            : AppColors.textTertiary,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 10,
                      ),
                    ),
                    if (timestamps[stepIndex] != null)
                      Text(
                        Formatters.formatTime(timestamps[stepIndex]!),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.h4);
  }
}

// ─── Item Card ────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
            color: AppColors.primaryMedium.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: AppColors.primaryMedium,
              size: AppSizes.iconLg,
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.listing!.name, style: AppTextStyles.h6),
                Text('Quantity: x${order.quantity}',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            Formatters.formatNPR(order.totalAmount),
            style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium),
          ),
        ],
      ),
    );
  }
}

// ─── Vendor Card ──────────────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendor});
  final dynamic vendor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppShadows.xs,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.primaryLight,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.businessName, style: AppTextStyles.h6),
                if (vendor.address != null && vendor.address.isNotEmpty)
                  Text(vendor.address, style: AppTextStyles.caption,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────

class _InfoRowData {
  const _InfoRowData(this.label, this.value);
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: AppShadows.xs,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.s4, vertical: AppSizes.s3),
                child: Row(
                  children: [
                    Text(row.label, style: AppTextStyles.bodySmall),
                    const Spacer(),
                    Text(
                      row.value,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, indent: AppSizes.s4, endIndent: AppSizes.s4),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Review button ────────────────────────────────────────────────────────

class _ReviewButton extends ConsumerWidget {
  const _ReviewButton({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(orderReviewProvider(order.id));
    return reviewAsync.when(
      data: (existing) => AppButton(
        label: existing != null ? 'Edit Your Review' : 'Rate This Pickup',
        onPressed: () => context.push(
          '/customer/orders/${order.id}/review',
          extra: {
            'vendorId': order.vendorId,
            'vendorName': order.vendor?.businessName ?? 'Vendor',
            'existingReview': existing,
          },
        ),
        icon: existing != null ? Icons.edit_rounded : Icons.star_rounded,
        variant: existing != null
            ? AppButtonVariant.secondary
            : AppButtonVariant.primary,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
