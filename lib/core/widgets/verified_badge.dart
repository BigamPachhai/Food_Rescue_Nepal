import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verified Vendor',
      child: Icon(
        Icons.verified_rounded,
        size: size,
        color: AppColors.primaryMedium,
      ),
    );
  }
}
