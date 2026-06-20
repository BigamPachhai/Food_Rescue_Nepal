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

class VendorReviewsScreen extends ConsumerStatefulWidget {
  const VendorReviewsScreen({super.key, required this.vendorId, this.canRespond = false});
  final String vendorId;
  final bool canRespond;

  @override
  ConsumerState<VendorReviewsScreen> createState() => _VendorReviewsScreenState();
}

class _VendorReviewsScreenState extends ConsumerState<VendorReviewsScreen> {
  int? _starFilter; // null = all
  String _sort = 'newest'; // newest | best | worst

  List<ReviewEntity> _process(List<ReviewEntity> reviews) {
    var list = _starFilter == null
        ? reviews
        : reviews.where((r) => r.rating == _starFilter).toList();
    switch (_sort) {
      case 'best':
        list = [...list]..sort((a, b) => b.rating.compareTo(a.rating));
      case 'worst':
        list = [...list]..sort((a, b) => a.rating.compareTo(b.rating));
      default:
        list = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(vendorReviewsProvider(widget.vendorId));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Customer Reviews'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort',
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'newest', child: Row(children: [
                if (_sort == 'newest') const Icon(Icons.check, size: 16, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('Newest first'),
              ])),
              PopupMenuItem(value: 'best', child: Row(children: [
                if (_sort == 'best') const Icon(Icons.check, size: 16, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('Highest rated'),
              ])),
              PopupMenuItem(value: 'worst', child: Row(children: [
                if (_sort == 'worst') const Icon(Icons.check, size: 16, color: AppColors.primaryMedium),
                const SizedBox(width: 4), const Text('Lowest rated'),
              ])),
            ],
          ),
        ],
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyStateView(
              icon: Icons.star_border_outlined,
              title: 'No reviews yet',
              subtitle: 'Reviews from customers will appear here.',
            );
          }

          final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          final counts = List.generate(5, (i) {
            final star = 5 - i;
            return reviews.where((r) => r.rating == star).length;
          });
          final processed = _process(reviews);

          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () => ref.read(vendorReviewsProvider(widget.vendorId).notifier).fetch(),
            child: ListView(
              children: [
                _RatingSummary(avg: avg, total: reviews.length, counts: counts),
                // Star filter chips
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: [null, 5, 4, 3, 2, 1].map((star) {
                      final sel = _starFilter == star;
                      final label = star == null ? 'All' : '$star ★';
                      final count = star == null
                          ? reviews.length
                          : reviews.where((r) => r.rating == star).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('$label ($count)'),
                          selected: sel,
                          onSelected: (_) => setState(() => _starFilter = star),
                          selectedColor: AppColors.accentAmber,
                          labelStyle: TextStyle(
                            color: sel ? Colors.white : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: sel ? AppColors.accentAmber : AppColors.neutral300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),
                if (processed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No reviews for this rating.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ...processed.map((r) => _ReviewCard(
                        review: r,
                        canRespond: widget.canRespond,
                        onRespond: () => _showRespondDialog(context, ref, r),
                      )),
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
          error: e,
          onRetry: () => ref.read(vendorReviewsProvider(widget.vendorId).notifier).fetch(),
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
          .read(vendorReviewsProvider(widget.vendorId).notifier)
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
                            backgroundColor: AppColors.neutral200,
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
  const _ReviewCard({required this.review, required this.canRespond, required this.onRespond});
  final ReviewEntity review;
  final bool canRespond;
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
            if (canRespond) ...[
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
          ],
        ),
      ),
    );
  }
}
