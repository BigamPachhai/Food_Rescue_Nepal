import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  _StatusStyle get _style {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return _StatusStyle(
          color: AppColors.statusPending,
          surface: AppColors.statusPendingSurface,
          label: 'Pending',
          icon: Icons.schedule_rounded,
        );
      case 'ACCEPTED':
        return _StatusStyle(
          color: AppColors.statusAccepted,
          surface: AppColors.statusAcceptedSurface,
          label: 'Accepted',
          icon: Icons.thumb_up_rounded,
        );
      case 'READY':
        return _StatusStyle(
          color: AppColors.statusReady,
          surface: AppColors.statusReadySurface,
          label: 'Ready for Pickup',
          icon: Icons.check_circle_rounded,
        );
      case 'COMPLETED':
        return _StatusStyle(
          color: AppColors.statusCompleted,
          surface: AppColors.statusCompletedSurface,
          label: 'Completed',
          icon: Icons.verified_rounded,
        );
      case 'CANCELLED':
        return _StatusStyle(
          color: AppColors.statusCancelled,
          surface: AppColors.statusCancelledSurface,
          label: 'Cancelled',
          icon: Icons.cancel_rounded,
        );
      case 'REJECTED':
        return _StatusStyle(
          color: AppColors.statusRejected,
          surface: AppColors.statusRejectedSurface,
          label: 'Rejected',
          icon: Icons.block_rounded,
        );
      case 'EXPIRED':
        return _StatusStyle(
          color: AppColors.statusExpired,
          surface: AppColors.statusExpiredSurface,
          label: 'Expired',
          icon: Icons.timer_off_rounded,
        );
      default:
        return _StatusStyle(
          color: AppColors.textSecondary,
          surface: AppColors.neutral100,
          label: status,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: compact ? 11 : 13, color: s.color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              compact ? _compactLabel(s.label) : s.label,
              style: compact ? s.captionStyle : s.labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _compactLabel(String label) {
    if (label == 'Ready for Pickup') return 'Ready';
    return label;
  }
}

class _StatusStyle {
  _StatusStyle({
    required this.color,
    required this.surface,
    required this.label,
    required this.icon,
  })  : captionStyle = AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        labelStyle = AppTextStyles.label.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        );

  final Color color;
  final Color surface;
  final String label;
  final IconData icon;
  // Pre-computed so build() never allocates a new TextStyle.
  final TextStyle captionStyle;
  final TextStyle labelStyle;
}
