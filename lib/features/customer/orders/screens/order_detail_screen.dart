import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
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
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder() async {
    setState(() => _isCancelling = true);
    try {
      await ref
          .read(dioClientProvider)
          .post(ApiEndpoints.orderCancel(widget.orderId));
      if (mounted) {
        context.showSnackBar('Order cancelled');
        ref.invalidate(orderDetailProvider(widget.orderId));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isCancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTimeline(order.status),
              const SizedBox(height: AppSizes.xxl),
              if (order.listing != null) ...[
                Text('Item', style: AppTextStyles.h5),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fastfood_outlined,
                          color: AppColors.primaryMedium),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.listing!.name, style: AppTextStyles.h6),
                            Text('x${order.quantity}',
                                style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      Text(
                        Formatters.formatNPR(order.totalAmount),
                        style: AppTextStyles.h6
                            .copyWith(color: AppColors.primaryMedium),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              if (order.vendor != null) ...[
                Text('Vendor', style: AppTextStyles.h5),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primarySurface,
                    child: Icon(Icons.store, color: AppColors.primaryLight),
                  ),
                  title: Text(order.vendor!.businessName,
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text(order.vendor!.address ?? '',
                      style: AppTextStyles.caption),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              Text('Order Info', style: AppTextStyles.h5),
              const SizedBox(height: 8),
              _InfoRow('Order ID',
                  '#${order.id.substring(0, 8).toUpperCase()}'),
              _InfoRow('Placed at',
                  Formatters.formatDateTime(order.createdAt)),
              _InfoRow('Total', Formatters.formatNPR(order.totalAmount)),
              const _InfoRow('Payment', 'Cash on Pickup'),
              const SizedBox(height: AppSizes.xxl),
              if (order.canShowQr)
                AppButton(
                  label: 'Show QR Code',
                  onPressed: () =>
                      context.push('/customer/orders/${order.id}/qr'),
                  icon: Icons.qr_code,
                ),
              if (order.canCancel) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel Order',
                  onPressed: _isCancelling ? null : _cancelOrder,
                  isLoading: _isCancelling,
                  variant: AppButtonVariant.secondary,
                ),
              ],
              if (order.status == 'PICKED_UP') ...[
                const SizedBox(height: 12),
                _ReviewButton(order: order),
              ],
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryMedium),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    const steps = ['PENDING', 'CONFIRMED', 'READY', 'PICKED_UP'];
    const labels = ['Placed', 'Confirmed', 'Ready', 'Picked Up'];
    final currentIndex = steps.indexOf(currentStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Status', style: AppTextStyles.h5),
        const SizedBox(height: 16),
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final stepIndex = i ~/ 2;
              final isDone = stepIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isDone
                      ? AppColors.primaryMedium
                      : AppColors.primarySurface,
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
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primaryMedium,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.primaryLight, width: 3),
                          ),
                        ),
                      )
                    : Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primaryMedium
                              : AppColors.primarySurface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDone
                                ? AppColors.primaryMedium
                                : AppColors.textSecondary,
                          ),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                const SizedBox(height: 4),
                Text(
                  labels[stepIndex],
                  style: AppTextStyles.caption.copyWith(
                    color: isDone || isCurrent
                        ? AppColors.primaryMedium
                        : AppColors.textSecondary,
                    fontWeight:
                        isCurrent ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _ReviewButton extends ConsumerWidget {
  const _ReviewButton({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewAsync = ref.watch(orderReviewProvider(order.id));
    return reviewAsync.when(
      data: (existing) => AppButton(
        label: existing != null ? 'Edit Your Review' : 'Rate This Order',
        onPressed: () => context.push(
          '/customer/orders/${order.id}/review',
          extra: {
            'vendorId': order.vendorId,
            'vendorName': order.vendor?.businessName ?? 'Vendor',
            'existingReview': existing,
          },
        ),
        icon: existing != null ? Icons.edit : Icons.star_outline,
        variant: existing != null ? AppButtonVariant.secondary : AppButtonVariant.primary,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
