import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
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

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen>
    with TickerProviderStateMixin {
  late int _rating;
  late final TextEditingController _commentCtrl;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _showSuccess = false;

  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;

  bool get _isEditing => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingReview?.rating ?? 0;
    _commentCtrl = TextEditingController(text: widget.existingReview?.comment ?? '');

    _successCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut),
    );
    _successOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _successCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0) {
      HapticFeedback.heavyImpact();
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
            'comment': _commentCtrl.text.trim().isEmpty
                ? null
                : _commentCtrl.text.trim(),
          },
        );
      }
      ref.invalidate(orderReviewProvider(widget.orderId));
      ref.invalidate(myReviewsProvider);
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _isSaving = false;
          _showSuccess = true;
        });
        await _successCtrl.forward();
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.showErrorSnackBar(e.toString());
        setState(() => _isSaving = false);
      }
    }
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
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    HapticFeedback.mediumImpact();
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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Review' : 'Rate Your Order'),
        actions: [
          if (_isEditing)
            _isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.s4),
                    child: SizedBox(
                      width: AppSizes.iconMd,
                      height: AppSizes.iconMd,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: _delete,
                    tooltip: 'Delete review',
                  ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.pageHorizontalPadding,
              vertical: AppSizes.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _VendorCard(vendorName: widget.vendorName),
                const SizedBox(height: AppSizes.sectionSpacing),
                _RatingSection(
                  rating: _rating,
                  onChanged: (r) {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = r);
                  },
                ),
                const SizedBox(height: AppSizes.sectionSpacing),
                _CommentSection(controller: _commentCtrl),
                const SizedBox(height: AppSizes.s8),
                AppButton(
                  label: _isEditing ? 'Update Review' : 'Submit Review',
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                  icon: _isEditing ? Icons.edit_outlined : Icons.star_outline_rounded,
                ),
                const SizedBox(height: AppSizes.s4),
              ],
            ),
          ),
          if (_showSuccess)
            _SuccessOverlay(
              scale: _successScale,
              opacity: _successOpacity,
              isEditing: _isEditing,
            ),
        ],
      ),
    );
  }
}

// ── Vendor card ──────────────────────────────────────────────────────────────

class _VendorCard extends StatelessWidget {
  const _VendorCard({required this.vendorName});
  final String vendorName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.s10,
            height: AppSizes.s10,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.primaryLight,
              size: AppSizes.iconLg,
            ),
          ),
          const SizedBox(width: AppSizes.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendorName, style: AppTextStyles.h5),
                const SizedBox(height: AppSizes.s1),
                Text('How was your experience?', style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rating section ───────────────────────────────────────────────────────────

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating, required this.onChanged});
  final int rating;
  final ValueChanged<int> onChanged;

  static const _labels = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent!'];
  static const _labelColors = [
    Colors.transparent,
    AppColors.error,
    AppColors.warning,
    AppColors.accentAmber,
    AppColors.primaryLight,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overall Rating', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s4),
        Center(child: _AnimatedStarPicker(value: rating, onChanged: onChanged)),
        const SizedBox(height: AppSizes.s3),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: rating > 0
                ? Text(
                    _labels[rating],
                    key: ValueKey(rating),
                    style: AppTextStyles.h3.copyWith(color: _labelColors[rating]),
                  )
                : const SizedBox(
                    key: ValueKey(0),
                    height: AppSizes.s6,
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Animated star picker ─────────────────────────────────────────────────────

class _AnimatedStarPicker extends StatefulWidget {
  const _AnimatedStarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_AnimatedStarPicker> createState() => _AnimatedStarPickerState();
}

class _AnimatedStarPickerState extends State<_AnimatedStarPicker>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scales;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
        value: 1.0,
      ),
    );
    _scales = _controllers
        .map(
          (c) => Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.elasticOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int star) {
    for (var i = 0; i < star; i++) {
      Future.delayed(Duration(milliseconds: i * 45), () {
        if (mounted) _controllers[i].forward(from: 0.0);
      });
    }
    widget.onChanged(star);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= widget.value;
        return GestureDetector(
          onTap: () => _onTap(star),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2),
            child: ScaleTransition(
              scale: _scales[i],
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  key: ValueKey(filled),
                  size: AppSizes.iconXl,
                  color: filled ? AppColors.accentAmber : AppColors.neutral300,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Comment section ──────────────────────────────────────────────────────────

class _CommentSection extends StatelessWidget {
  const _CommentSection({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Review', style: AppTextStyles.h4),
        const SizedBox(height: AppSizes.s1),
        Text('Optional — share your experience', style: AppTextStyles.caption),
        const SizedBox(height: AppSizes.s3),
        TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 1000,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: "Tell others what you loved (or didn't love) about this vendor…",
            hintStyle: AppTextStyles.bodySmall,
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusInput),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusInput),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusInput),
              borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(AppSizes.cardPadding),
          ),
        ),
      ],
    );
  }
}

// ── Success overlay ──────────────────────────────────────────────────────────

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({
    required this.scale,
    required this.opacity,
    required this.isEditing,
  });
  final Animation<double> scale;
  final Animation<double> opacity;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: ColoredBox(
        color: AppColors.backgroundLight.withValues(alpha: 0.9),
        child: Center(
          child: ScaleTransition(
            scale: scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSizes.s16,
                  height: AppSizes.s16,
                  decoration: const BoxDecoration(
                    color: AppColors.successSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.success,
                    size: AppSizes.iconXl,
                  ),
                ),
                const SizedBox(height: AppSizes.s4),
                Text(
                  isEditing ? 'Review Updated!' : 'Review Submitted!',
                  style: AppTextStyles.h3.copyWith(color: AppColors.success),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  'Thank you for your feedback',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
