import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../providers/reviews_provider.dart';

class VendorReviewsScreen extends ConsumerWidget {
  const VendorReviewsScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(vendorReviewsProvider(vendorId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(title: const Text('Customer Reviews')),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyStateView(
              icon: Icons.star_border_outlined,
              title: 'No reviews yet',
              subtitle: 'Reviews from customers will appear here.',
            );
          }

          // Rating summary
          final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;
          final counts = List.generate(5, (i) {
            final star = 5 - i;
            return reviews.where((r) => r.rating == star).length;
          });

          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () => ref.read(vendorReviewsProvider(vendorId).notifier).fetch(),
            child: ListView(
              children: [
                _RatingSummary(avg: avg, total: reviews.length, counts: counts),
                const Divider(height: 1),
                ...reviews.map(
                  (r) => _ReviewCard(
                    review: r,
                    onRespond: () => _showRespondDialog(context, ref, r),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ShimmerCard(height: 100),
          ),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(vendorReviewsProvider(vendorId).notifier).fetch(),
        ),
      ),
    );
  }

  Future<void> _showRespondDialog(
      BuildContext context, WidgetRef ref, ReviewEntity review) async {
    final ctrl = TextEditingController(text: review.vendorResponse ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(review.vendorResponse != null ? 'Edit Response' : 'Respond to Review'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Thank you for your feedback…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty || !context.mounted) return;
    try {
      await ref
          .read(vendorReviewsProvider(vendorId).notifier)
          .addResponse(review.id, ctrl.text.trim());
      if (context.mounted) context.showSnackBar('Response saved');
    } catch (e) {
      if (context.mounted) context.showErrorSnackBar(e.toString());
    }
  }
}

// ─── Rating summary ────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({
    required this.avg,
    required this.total,
    required this.counts,
  });
  final double avg;
  final int total;
  final List<int> counts; // [5-star count, 4-star, 3-star, 2-star, 1-star]

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big number
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.accentAmber,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text('$total reviews', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(width: 24),
          // Bar breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = counts[i];
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: AppTextStyles.caption),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: AppColors.accentAmber),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: const Color(0xFFEEEEEE),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.accentAmber),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 24,
                        child: Text('$count',
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review card ───────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onRespond});
  final ReviewEntity review;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : 'C',
                    style: AppTextStyles.h6
                        .copyWith(color: AppColors.primaryMedium),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.customerName, style: AppTextStyles.h6),
                      Text(
                        Formatters.timeAgo(review.createdAt),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment!, style: AppTextStyles.bodySmall),
            ],
            // Vendor response
            if (review.vendorResponse != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 14, color: AppColors.primaryMedium),
                        const SizedBox(width: 4),
                        Text('Vendor Response',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryMedium,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review.vendorResponse!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRespond,
                icon: Icon(
                  review.vendorResponse != null ? Icons.edit : Icons.reply,
                  size: 16,
                ),
                label: Text(
                  review.vendorResponse != null ? 'Edit Response' : 'Respond',
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryMedium,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
