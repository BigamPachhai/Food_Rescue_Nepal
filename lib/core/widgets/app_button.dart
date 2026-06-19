import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, text, danger }
enum AppButtonSize { md, sm }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final IconData? trailingIcon;
  final double? width;

  double get _height =>
      size == AppButtonSize.sm ? AppSizes.buttonHeightSm : AppSizes.buttonHeight;
  TextStyle get _labelStyle =>
      size == AppButtonSize.sm ? AppTextStyles.buttonSm : AppTextStyles.button;
  double get _iconSize => size == AppButtonSize.sm ? 16 : 18;

  VoidCallback? _withHaptic(VoidCallback? cb) {
    if (cb == null) return null;
    return () {
      HapticFeedback.mediumImpact();
      cb();
    };
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: _iconSize, color: textColor),
          const SizedBox(width: 6),
        ],
        Text(label, style: _labelStyle.copyWith(color: textColor)),
        if (trailingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(trailingIcon, size: _iconSize, color: textColor),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? double.infinity;
    final isDisabled = isLoading || onPressed == null;

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: effectiveWidth,
          height: _height,
          child: ElevatedButton(
            onPressed: isDisabled ? null : _withHaptic(onPressed),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMedium,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: AppColors.neutral200,
              disabledForegroundColor: AppColors.neutral400,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: _buildContent(
              isDisabled ? AppColors.neutral400 : AppColors.textOnPrimary,
            ),
          ),
        );

      case AppButtonVariant.secondary:
        return SizedBox(
          width: effectiveWidth,
          height: _height,
          child: OutlinedButton(
            onPressed: isDisabled ? null : _withHaptic(onPressed),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryMedium,
              disabledForegroundColor: AppColors.neutral400,
              side: BorderSide(
                color: isDisabled ? AppColors.neutral200 : AppColors.primaryMedium,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: _buildContent(
              isDisabled ? AppColors.neutral400 : AppColors.primaryMedium,
            ),
          ),
        );

      case AppButtonVariant.danger:
        return SizedBox(
          width: effectiveWidth,
          height: _height,
          child: ElevatedButton(
            onPressed: isDisabled ? null : _withHaptic(onPressed),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorSurface,
              foregroundColor: AppColors.error,
              disabledBackgroundColor: AppColors.neutral200,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusButton),
              ),
            ),
            child: _buildContent(
              isDisabled ? AppColors.neutral400 : AppColors.error,
            ),
          ),
        );

      case AppButtonVariant.text:
        return SizedBox(
          height: _height,
          width: effectiveWidth == double.infinity ? null : effectiveWidth,
          child: TextButton(
            onPressed: isDisabled ? null : _withHaptic(onPressed),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryMedium,
              padding: EdgeInsets.symmetric(
                horizontal: size == AppButtonSize.sm ? 8 : 12,
              ),
            ),
            child: _buildContent(
              isDisabled ? AppColors.neutral400 : AppColors.primaryMedium,
            ),
          ),
        );
    }
  }
}
