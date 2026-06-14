import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../providers/vendor_orders_provider.dart';

class VendorOrderDetailScreen extends ConsumerStatefulWidget {
  const VendorOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState
    extends ConsumerState<VendorOrderDetailScreen> {
  bool _isActing = false;

  Future<void> _performAction(Future<void> Function() action) async {
    setState(() => _isActing = true);
    try {
      await action();
      if (mounted) {
        ref.invalidate(vendorOrderDetailProvider(widget.orderId));
        ref.read(vendorOrdersProvider.notifier).fetch();
        context.showSnackBar('Updated successfully');
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isActing = false);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(vendorOrderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/vendor/scanner'),
            tooltip: 'Scan QR',
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    StatusBadge(status: order.status),
                    const SizedBox(height: 8),
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: AppTextStyles.h4,
                    ),
                    Text(
                      Formatters.formatDateTime(order.createdAt),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // Item
              if (order.listing != null) ...[
                Text('Item', style: AppTextStyles.h5),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fastfood_outlined,
                        color: AppColors.primaryLight),
                  ),
                  title: Text(order.listing!.name,
                      style: AppTextStyles.bodyMedium),
                  subtitle: Text('x${order.quantity}',
                      style: AppTextStyles.caption),
                  trailing: Text(Formatters.formatNPR(order.totalAmount),
                      style: AppTextStyles.h6
                          .copyWith(color: AppColors.primaryMedium)),
                ),
              ],

              const SizedBox(height: AppSizes.lg),
              if (order.pickupCode != null) ...[
                Text('Pickup Code', style: AppTextStyles.h5),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Text(
                    order.pickupCode!,
                    style: AppTextStyles.h3.copyWith(
                      letterSpacing: 4,
                      color: AppColors.primaryMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.xxl),

              // Action buttons based on status
              if (order.status == 'PENDING') ...[
                AppButton(
                  label: 'Confirm Order',
                  isLoading: _isActing,
                  onPressed: () => _performAction(
                    () => ref
                        .read(vendorOrdersProvider.notifier)
                        .confirmOrder(order.id),
                  ),
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Cancel Order',
                  variant: AppButtonVariant.secondary,
                  isLoading: _isActing,
                  onPressed: () => _performAction(
                    () => ref
                        .read(vendorOrdersProvider.notifier)
                        .cancelOrder(order.id),
                  ),
                ),
              ] else if (order.status == 'CONFIRMED') ...[
                AppButton(
                  label: 'Mark as Ready',
                  isLoading: _isActing,
                  onPressed: () => _performAction(
                    () => ref
                        .read(vendorOrdersProvider.notifier)
                        .markReady(order.id),
                  ),
                  icon: Icons.check_circle_outline,
                ),
              ] else if (order.status == 'READY') ...[
                AppButton(
                  label: 'Scan QR to Complete',
                  onPressed: () => context.push('/vendor/scanner'),
                  icon: Icons.qr_code_scanner,
                ),
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
              ref.invalidate(vendorOrderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }
}
