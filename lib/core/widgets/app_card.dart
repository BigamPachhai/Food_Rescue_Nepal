import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_shadows.dart';
import '../constants/app_sizes.dart';

enum AppCardVariant { elevated, outlined, filled }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.borderColor,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppSizes.radiusCard);
    final bg = color ?? AppColors.cardLight;

    List<BoxShadow> shadows = [];
    Border? border;

    switch (variant) {
      case AppCardVariant.elevated:
        shadows = AppShadows.card;
      case AppCardVariant.outlined:
        border = Border.all(color: borderColor ?? AppColors.border);
      case AppCardVariant.filled:
        break;
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: shadows,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: AppColors.primarySurface,
          highlightColor: AppColors.primarySurface.withValues(alpha: 0.5),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSizes.cardPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
