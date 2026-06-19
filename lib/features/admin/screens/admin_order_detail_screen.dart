import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class AdminOrderDetailScreen extends ConsumerWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(adminOrderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long,
                        size: 40, color: AppColors.primaryMedium),
                    const SizedBox(height: 12),
                    Text(
                      order.listingName ?? 'Order',
                      style: AppTextStyles.h3,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(status: order.status),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _Section(
                title: 'Order Info',
                children: [
                  _Row('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                  _Row('Date', Formatters.formatDate(order.createdAt)),
                  _Row('Quantity', '${order.quantity}'),
                  _Row('Total', Formatters.formatNPR(order.totalAmount)),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _Section(
                title: 'Customer',
                children: [
                  if (order.customerName != null)
                    _Row('Name', order.customerName!),
                  if (order.customerEmail != null)
                    _Row('Email', order.customerEmail!),
                  if (order.customerPhone != null)
                    _Row('Phone', order.customerPhone!),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _Section(
                title: 'Vendor',
                children: [
                  if (order.vendorName != null)
                    _Row('Business', order.vendorName!),
                  if (order.vendorAddress != null)
                    _Row('Address', order.vendorAddress!),
                ],
              ),
            ],
          ),
        ),
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const ShimmerCard(height: 100),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(adminOrderDetailProvider(orderId)),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.h6.copyWith(color: AppColors.primaryMedium)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primarySurface),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
