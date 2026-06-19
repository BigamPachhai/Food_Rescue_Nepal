import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

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
    final badge = Container(
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
    // Pulse animation for high-value discounts to draw attention
    if (percent >= 50) return _PulsingBadge(child: badge);
    return badge;
  }
}

class _PulsingBadge extends StatefulWidget {
  const _PulsingBadge({required this.child});
  final Widget child;

  @override
  State<_PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<_PulsingBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: _scale,
        child: widget.child,
      );
}
