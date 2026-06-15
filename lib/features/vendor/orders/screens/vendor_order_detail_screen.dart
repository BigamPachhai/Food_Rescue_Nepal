import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
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

  Future<void> _rejectReservation(String orderId) async {
    final confirm = await _showConfirmDialog(
      title: 'Reject Reservation',
      message:
          'Are you sure you want to reject this reservation? The quantity will be restored.',
      confirmLabel: 'Reject',
      isDestructive: true,
    );
    if (confirm != true) return;
    await _performAction(
      () => ref.read(vendorOrdersProvider.notifier).rejectReservation(orderId),
    );
    if (!mounted) return;
    context.pop();
  }

  Future<void> _expireReservation(String orderId) async {
    final confirm = await _showConfirmDialog(
      title: 'Mark as Expired',
      message:
          'Mark this reservation as expired? The customer did not pick up.',
      confirmLabel: 'Confirm',
      isDestructive: true,
    );
    if (confirm != true) return;
    await _performAction(
      () => ref.read(vendorOrdersProvider.notifier).expireReservation(orderId),
    );
    if (!mounted) return;
    context.pop();
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(title, style: AppTextStyles.h4),
        content: Text(message, style: AppTextStyles.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? AppColors.error : AppColors.primaryMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Reservation Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push('/vendor/scanner'),
            tooltip: 'Scan QR',
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusHeader(order: order),
              const SizedBox(height: AppSizes.s4),
              if (order.listing != null) ...[
                Text('Item', style: AppTextStyles.h4),
                const SizedBox(height: AppSizes.s2),
                _ItemCard(order: order),
              ],
              const SizedBox(height: AppSizes.s4),
              Text('Details', style: AppTextStyles.h4),
              const SizedBox(height: AppSizes.s2),
              _InfoCard(rows: [
                _InfoRowData('Reservation ID',
                    '#${order.id.substring(0, 8).toUpperCase()}'),
                _InfoRowData(
                    'Created', Formatters.formatDateTime(order.createdAt)),
                _InfoRowData('Quantity', '×${order.quantity}'),
                _InfoRowData(
                    'Total', Formatters.formatNPR(order.totalAmount)),
                const _InfoRowData('Payment', 'Cash on Pickup'),
              ]),
              if (order.pickupCode != null) ...[
                const SizedBox(height: AppSizes.s4),
                Text('Pickup Code', style: AppTextStyles.h4),
                const SizedBox(height: AppSizes.s2),
                _PickupCodeCard(code: order.pickupCode!),
              ],
              const SizedBox(height: AppSizes.s5),
              _buildActionButtons(order),
              const SizedBox(height: AppSizes.s4),
            ],
          ),
        ),
        loading: () => const ShimmerVendorOrderDetail(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(vendorOrderDetailProvider(widget.orderId)),
        ),
      ),
    );
  }

  Widget _buildActionButtons(VendorOrder order) {
    if (order.status == 'PENDING') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Accept Reservation',
            isLoading: _isActing,
            onPressed: () => _performAction(
              () => ref
                  .read(vendorOrdersProvider.notifier)
                  .acceptOrder(order.id),
            ),
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: AppSizes.s2),
          AppButton(
            label: 'Reject Reservation',
            variant: AppButtonVariant.secondary,
            isLoading: _isActing,
            onPressed: () => _rejectReservation(order.id),
          ),
        ],
      );
    } else if (order.status == 'ACCEPTED') {
      return AppButton(
        label: 'Mark as Ready for Pickup',
        isLoading: _isActing,
        onPressed: () => _performAction(
          () =>
              ref.read(vendorOrdersProvider.notifier).markReady(order.id),
        ),
        icon: Icons.inventory_2_rounded,
      );
    } else if (order.status == 'READY') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: 'Scan QR to Complete',
            onPressed: () => context.push('/vendor/scanner'),
            icon: Icons.qr_code_scanner_rounded,
          ),
          const SizedBox(height: AppSizes.s2),
          AppButton(
            label: 'Mark as Expired',
            variant: AppButtonVariant.secondary,
            isLoading: _isActing,
            onPressed: () => _expireReservation(order.id),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

// ─── Status Header ────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.order});
  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final (bgColor, borderColor) = _colorsForStatus(order.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4, vertical: AppSizes.s4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: borderColor),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          StatusBadge(status: order.status),
          const SizedBox(height: AppSizes.s2),
          Text(
            '#${order.id.substring(0, 8).toUpperCase()}',
            style: AppTextStyles.h4,
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.formatDateTime(order.createdAt),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSizes.s3),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.s4, vertical: AppSizes.s2),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
            child: Text(
              Formatters.formatNPR(order.totalAmount),
              style:
                  AppTextStyles.h4.copyWith(color: AppColors.primaryMedium),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colorsForStatus(String status) => switch (status) {
        'PENDING' => (AppColors.statusPendingSurface,
            AppColors.statusPending.withValues(alpha: 0.2)),
        'ACCEPTED' => (AppColors.infoSurface,
            AppColors.info.withValues(alpha: 0.2)),
        'READY' => (AppColors.primarySurface,
            AppColors.primaryMedium.withValues(alpha: 0.2)),
        'COMPLETED' => (AppColors.successSurface,
            AppColors.success.withValues(alpha: 0.2)),
        _ => (AppColors.neutral50, AppColors.border),
      };
}

// ─── Item Card ────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.order});
  final VendorOrder order;

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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: AppColors.primaryLight,
              size: AppSizes.iconLg,
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.listing!.name, style: AppTextStyles.h6),
                const SizedBox(height: 2),
                Text('Quantity: ×${order.quantity}',
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
                const Divider(
                    height: 1, indent: AppSizes.s4, endIndent: AppSizes.s4),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Pickup Code Card ─────────────────────────────────────────────────────

class _PickupCodeCard extends StatelessWidget {
  const _PickupCodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.s5, horizontal: AppSizes.s4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
            color: AppColors.primaryMedium.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_open_rounded,
                  color: AppColors.primaryMedium, size: AppSizes.iconMd),
              const SizedBox(width: AppSizes.s2),
              Text(
                'Pickup Code',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.s3),
          Text(
            code,
            style: AppTextStyles.h2.copyWith(
              letterSpacing: 6,
              color: AppColors.primaryMedium,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s2),
          Text(
            'Ask the customer for this code or scan their QR',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
