import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

// Cached TextStyles so .copyWith() is not called on every build.
final _kBadgeStyleSmall = AppTextStyles.caption.copyWith(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontSize: 10,
);
final _kBadgeStyleLarge = AppTextStyles.label.copyWith(
  color: Colors.white,
  fontWeight: FontWeight.w700,
  fontSize: 13,
);

class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.percent, this.large = false});

  final int percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (percent <= 0) return const SizedBox.shrink();
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.accentAmber,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: Text(
        '-$percent%',
        style: large ? _kBadgeStyleLarge : _kBadgeStyleSmall,
      ),
    );
  }
}
