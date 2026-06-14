import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primarySurface,
      highlightColor: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(
          vertical: AppSizes.sm,
          horizontal: AppSizes.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
      ),
    );
  }
}

class ShimmerListingCard extends StatelessWidget {
  const ShimmerListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.primarySurface,
      highlightColor: AppColors.primaryLight.withValues(alpha: 0.2),
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSizes.sm,
          horizontal: AppSizes.lg,
        ),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, color: AppColors.primarySurface),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: AppColors.primarySurface),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: AppColors.primarySurface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
