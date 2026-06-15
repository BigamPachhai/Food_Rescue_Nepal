import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';
import '../utils/error_parser.dart';
import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.message,
    required this.onRetry,
    this.error,
  });

  final String? message;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final appError = error != null
        ? AppError.from(error!)
        : AppError(
            type: ErrorType.unknown,
            message: message ?? 'Something went wrong.',
          );

    final color = _colorFor(appError.type);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s8,
          vertical: AppSizes.s8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(appError.type),
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.s5),
            Text(
              _titleFor(appError.type),
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s2),
            Text(
              appError.message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.s6),
            AppButton(
              label: 'Try Again',
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              width: 160,
              size: AppButtonSize.sm,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ErrorType type) => switch (type) {
        ErrorType.network => Icons.wifi_off_rounded,
        ErrorType.server => Icons.cloud_off_rounded,
        ErrorType.auth => Icons.lock_outline_rounded,
        ErrorType.timeout => Icons.timer_off_outlined,
        ErrorType.unknown => Icons.error_outline_rounded,
      };

  String _titleFor(ErrorType type) => switch (type) {
        ErrorType.network => 'No Internet',
        ErrorType.server => 'Server Error',
        ErrorType.auth => 'Session Expired',
        ErrorType.timeout => 'Timed Out',
        ErrorType.unknown => 'Something Went Wrong',
      };

  Color _colorFor(ErrorType type) => switch (type) {
        ErrorType.network => AppColors.warning,
        ErrorType.server => AppColors.error,
        ErrorType.auth => AppColors.info,
        ErrorType.timeout => AppColors.accentAmber,
        ErrorType.unknown => AppColors.error,
      };
}
