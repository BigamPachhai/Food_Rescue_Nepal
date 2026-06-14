import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/admin_provider.dart';

class AdminVendorsScreen extends ConsumerStatefulWidget {
  const AdminVendorsScreen({super.key});

  @override
  ConsumerState<AdminVendorsScreen> createState() =>
      _AdminVendorsScreenState();
}

class _AdminVendorsScreenState extends ConsumerState<AdminVendorsScreen> {
  String _statusFilter = '';

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(adminVendorsProvider(_statusFilter));

    return Scaffold(
      appBar: AppBar(title: const Text('Vendors')),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children:
                  ['', 'PENDING', 'APPROVED', 'SUSPENDED', 'REJECTED']
                      .map((s) {
                final label = s.isEmpty
                    ? 'All'
                    : s[0] + s.substring(1).toLowerCase();
                final selected = _statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _statusFilter = s),
                    selectedColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(
                      color:
                          selected ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryMedium
                          : AppColors.primarySurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: vendorsAsync.when(
              data: (vendors) {
                if (vendors.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.store_outlined,
                    title: 'No vendors found',
                    subtitle: 'Try adjusting your filter.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primaryMedium,
                  onRefresh: () async =>
                      ref.invalidate(adminVendorsProvider(_statusFilter)),
                  child: ListView.builder(
                    itemCount: vendors.length,
                    itemBuilder: (_, i) =>
                        _VendorTile(vendor: vendors[i]),
                  ),
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const ShimmerCard(height: 80),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref
                    .invalidate(adminVendorsProvider(_statusFilter)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({required this.vendor});
  final AdminVendor vendor;

  @override
  Widget build(BuildContext context) {
    final isPending = vendor.status == 'PENDING';
    return ListTile(
      leading: Stack(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.store, color: AppColors.primaryLight),
          ),
          if (isPending)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.statusPending,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(vendor.businessName, style: AppTextStyles.h6),
      subtitle: Text('${vendor.ownerEmail} · ${vendor.businessType}',
          style: AppTextStyles.caption),
      trailing: StatusBadge(status: vendor.status),
      onTap: () => context.push('/admin/vendors/${vendor.id}'),
    );
  }
}
