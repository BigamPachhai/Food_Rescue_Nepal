import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
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
  Timer? _countdownTimer;
  Duration _pickupTimeLeft = Duration.zero;

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
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final order = ref.read(orderDetailProvider(widget.orderId)).value;
      if (order == null || !order.isActive) return;
      final pickupEnd = order.listing?.pickupEnd;
      if (pickupEnd == null) return;
      final left = pickupEnd.difference(DateTime.now());
      setState(() => _pickupTimeLeft = left.isNegative ? Duration.zero : left);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder() async {
    String? selectedReason;
    const reasons = [
      'Changed my mind',
      'Found a better option',
      'Pickup time doesn\'t work',
      'Ordered by mistake',
      'Other',
    ];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          title: const Text('Cancel Reservation?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Why are you cancelling?'),
              const SizedBox(height: 12),
              ...reasons.map((r) {
                    final selected = selectedReason == r;
                    return InkWell(
                      onTap: () => setLocal(() => selectedReason = r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? AppColors.primaryMedium : AppColors.neutral300,
                                  width: selected ? 6 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(r, style: AppTextStyles.bodySmall)),
                          ],
                        ),
                      ),
                    );
                  }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it'),
            ),
            TextButton(
              onPressed: selectedReason == null ? null : () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Yes, cancel'),
            ),
          ],
        ),
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
      ref.invalidate(customerOrdersProvider);
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
      appBar: AppBar(
        title: const Text('Reservation Details'),
        actions: [
          orderAsync.whenOrNull(
            data: (order) => IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy order ID',
              onPressed: () {
                Clipboard.setData(ClipboardData(
                    text: '#${order.id.substring(0, 8).toUpperCase()}'));
                context.showSnackBar('Order ID copied');
              },
            ),
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTimeline(order),
              if (order.isActive && order.listing != null) ...[
                const SizedBox(height: AppSizes.s3),
                _buildPickupCountdown(order),
              ],
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
                _VendorCard(vendor: order.vendor!, vendorId: order.vendorId),
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
                  if (order.notes != null && order.notes!.isNotEmpty)
                    _InfoRowData('Your note', order.notes!),
                ],
              ),
              const SizedBox(height: AppSizes.s5),
              if (order.canShowQr)
                AppButton(
                  label: 'Show QR Code',
                  onPressed: () =>
                      context.push('/customer/qr/${order.id}'),
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
              ] else if (order.status == 'PENDING') ...[
                const SizedBox(height: AppSizes.s2),
                Container(
                  padding: const EdgeInsets.all(AppSizes.s3),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                      const SizedBox(width: AppSizes.s2),
                      Expanded(
                        child: Text(
                          'Cancellation window has passed (10 min). Contact the vendor if you need to cancel.',
                          style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (order.status == 'COMPLETED') ...[
                const SizedBox(height: AppSizes.s2),
                _ReviewButton(order: order),
                if (order.listing != null) ...[
                  const SizedBox(height: AppSizes.s2),
                  _ReorderButton(listingId: order.listingId),
                ],
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

  Widget _buildPickupCountdown(OrderEntity order) {
    final timeLeft = _pickupTimeLeft;
    final isUrgent = timeLeft.inMinutes <= 30;
    final color = isUrgent ? AppColors.error : AppColors.primaryMedium;
    final bgColor = isUrgent ? AppColors.errorSurface : AppColors.primarySurface;

    final h = timeLeft.inHours;
    final m = timeLeft.inMinutes.remainder(60);
    final s = timeLeft.inSeconds.remainder(60);
    final label = h > 0
        ? '${h}h ${m}m remaining to pick up'
        : timeLeft.inSeconds <= 0
            ? 'Pickup window closed'
            : '${m}m ${s}s remaining to pick up';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.s4, vertical: AppSizes.s3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(isUrgent ? Icons.timer_off_rounded : Icons.timer_rounded, color: color, size: 20),
          const SizedBox(width: AppSizes.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w600)),
                Text(
                  'Pickup: ${Formatters.formatPickupTime(order.listing!.pickupStart, order.listing!.pickupEnd)}',
                  style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ],
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3, vertical: AppSizes.s2),
              decoration: BoxDecoration(
                color: AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                  const SizedBox(width: AppSizes.s2),
                  Text(
                    'Reservation cancelled',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
  const _VendorCard({required this.vendor, required this.vendorId});
  final dynamic vendor;
  final String vendorId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/customer/vendor/$vendorId'),
      child: Container(
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
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
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

// ─── Re-order button ──────────────────────────────────────────────────────

class _ReorderButton extends StatelessWidget {
  const _ReorderButton({required this.listingId});
  final String listingId;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push('/customer/listing/$listingId'),
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Order Again'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        foregroundColor: AppColors.primaryMedium,
        side: const BorderSide(color: AppColors.primaryMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
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
