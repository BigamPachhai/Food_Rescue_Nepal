import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/reviews_provider.dart';

class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.orderId,
    required this.vendorId,
    required this.vendorName,
    this.existingReview,
  });

  final String orderId;
  final String vendorId;
  final String vendorName;
  final ReviewEntity? existingReview;

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  late int _rating;
  late final TextEditingController _commentCtrl;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentCtrl = TextEditingController(text: widget.existingReview?.comment ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      context.showErrorSnackBar('Please select a star rating');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioClientProvider);
      if (_isEditing) {
        await dio.put(
          ApiEndpoints.reviewById(widget.existingReview!.id),
          data: {'rating': _rating, 'comment': _commentCtrl.text.trim()},
        );
      } else {
        await dio.post(
          ApiEndpoints.reviews,
          data: {
            'orderId': widget.orderId,
            'rating': _rating,
            'comment': _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          },
        );
      }
      ref.invalidate(orderReviewProvider(widget.orderId));
      ref.invalidate(myReviewsProvider);
      if (mounted) {
        context.showSnackBar(_isEditing ? 'Review updated!' : 'Review submitted!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.reviewById(widget.existingReview!.id));
      ref.invalidate(orderReviewProvider(widget.orderId));
      ref.invalidate(myReviewsProvider);
      if (mounted) {
        context.showSnackBar('Review deleted');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isDeleting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Review' : 'Rate Your Order'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _isDeleting ? null : _delete,
              tooltip: 'Delete review',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor name
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.store, color: AppColors.primaryLight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.vendorName, style: AppTextStyles.h5),
                        Text('How was your experience?',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Star rating
            Text('Overall Rating', style: AppTextStyles.h5),
            const SizedBox(height: 12),
            _StarRatingPicker(
              value: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            if (_rating > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _ratingLabel(_rating),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Comment
            Text('Your Review (optional)', style: AppTextStyles.h5),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                    'Tell others what you loved (or didn\'t love) about this vendor…',
                hintStyle: AppTextStyles.bodySmall,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryMedium),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: _isEditing ? 'Update Review' : 'Submit Review',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
              icon: _isEditing ? Icons.edit : Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}

class _StarRatingPicker extends StatelessWidget {
  const _StarRatingPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        return GestureDetector(
          onTap: () => onChanged(star),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 44,
              color: star <= value ? AppColors.accentAmber : const Color(0xFFCCCCCC),
            ),
          ),
        );
      }),
    );
  }
}
