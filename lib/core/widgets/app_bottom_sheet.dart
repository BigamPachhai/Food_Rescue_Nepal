import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

/// Shows a consistent bottom sheet with a drag handle and optional title.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  bool isScrollControlled = true,
  double initialChildSize = 0.6,
  double minChildSize = 0.4,
  double maxChildSize = 0.95,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (_) => _AppBottomSheetWrapper(
      title: title,
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      child: child,
    ),
  );
}

class _AppBottomSheetWrapper extends StatelessWidget {
  const _AppBottomSheetWrapper({
    required this.child,
    this.title,
    required this.initialChildSize,
    required this.minChildSize,
    required this.maxChildSize,
  });

  final Widget child;
  final String? title;
  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusBottomSheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.s3),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral300,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                ),
              ),
            ),
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.s4,
                  AppSizes.s3,
                  AppSizes.s4,
                  AppSizes.s2,
                ),
                child: Row(
                  children: [
                    Text(title!, style: AppTextStyles.h4),
                  ],
                ),
              ),
              const Divider(height: 1),
            ] else
              const SizedBox(height: AppSizes.s2),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
