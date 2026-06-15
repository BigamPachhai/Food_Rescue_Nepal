import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';
import '../../../core/constants/api_endpoints.dart';

class AdminVendorDetailScreen extends ConsumerStatefulWidget {
  const AdminVendorDetailScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  ConsumerState<AdminVendorDetailScreen> createState() =>
      _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState
    extends ConsumerState<AdminVendorDetailScreen> {
  bool _isActing = false;

  Future<void> _action(String endpoint, String successMsg) async {
    setState(() => _isActing = true);
    try {
      await ref.read(dioClientProvider).post(endpoint);
      if (mounted) {
        context.showSnackBar(successMsg);
        ref.invalidate(adminVendorDetailProvider(widget.vendorId));
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isActing = false);
  }

  @override
  Widget build(BuildContext context) {
    final vendorAsync =
        ref.watch(adminVendorDetailProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Details')),
      body: vendorAsync.when(
        data: (vendor) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.store, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(vendor.businessName, style: AppTextStyles.h3),
                    Text(vendor.businessType,
                        style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    StatusBadge(status: vendor.status),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              _Row('Owner', vendor.ownerName),
              _Row('Email', vendor.ownerEmail),
              if (vendor.address != null) _Row('Address', vendor.address!),
              const SizedBox(height: AppSizes.xxl),
              // Action buttons based on status
              if (vendor.status == 'PENDING') ...[
                AppButton(
                  label: 'Approve Vendor',
                  onPressed: _isActing
                      ? null
                      : () => _action(
                            ApiEndpoints.adminApproveVendor(widget.vendorId),
                            'Vendor approved',
                          ),
                  isLoading: _isActing,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Reject Vendor',
                  variant: AppButtonVariant.secondary,
                  onPressed: _isActing
                      ? null
                      : () => _action(
                            ApiEndpoints.adminRejectVendor(widget.vendorId),
                            'Vendor rejected',
                          ),
                ),
              ] else if (vendor.status == 'APPROVED') ...[
                AppButton(
                  label: 'Suspend Vendor',
                  variant: AppButtonVariant.secondary,
                  onPressed: _isActing
                      ? null
                      : () => _action(
                            ApiEndpoints.adminSuspendVendor(widget.vendorId),
                            'Vendor suspended',
                          ),
                ),
              ] else if (vendor.status == 'SUSPENDED') ...[
                AppButton(
                  label: 'Reinstate Vendor',
                  onPressed: _isActing
                      ? null
                      : () => _action(
                            ApiEndpoints.adminApproveVendor(widget.vendorId),
                            'Vendor reinstated',
                          ),
                  isLoading: _isActing,
                ),
              ],
            ],
          ),
        ),
        loading: () => const ShimmerAdminDetail(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.invalidate(adminVendorDetailProvider(widget.vendorId)),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
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
