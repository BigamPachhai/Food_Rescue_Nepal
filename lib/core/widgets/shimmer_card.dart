import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

// ─── Base shimmer wrapper ──────────────────────────────────────────────────

Widget _shimmerWrap(Widget child) => Shimmer.fromColors(
      baseColor: AppColors.neutral100,
      highlightColor: AppColors.neutral50,
      child: child,
    );

Widget _box({
  double? height,
  double? width,
  double radius = AppSizes.radiusSm,
  Color color = Colors.white,
}) =>
    Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

Widget _circle(double size) => Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    );

// ─── Generic shimmer card ──────────────────────────────────────────────────

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, this.height = 100, this.margin});

  final double height;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      Container(
        height: height,
        margin: margin ??
            const EdgeInsets.symmetric(
              vertical: AppSizes.s1,
              horizontal: AppSizes.s4,
            ),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
      ),
    );
  }
}

// ─── Listing list card shimmer ─────────────────────────────────────────────

class ShimmerListingCard extends StatelessWidget {
  const ShimmerListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      Container(
        margin: const EdgeInsets.symmetric(
          vertical: AppSizes.s1,
          horizontal: AppSizes.s4,
        ),
        padding: const EdgeInsets.all(AppSizes.s4),
        decoration: BoxDecoration(
          color: AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, color: AppColors.neutral100),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 120, color: AppColors.neutral100),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 80, color: AppColors.neutral100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Listing detail skeleton ────────────────────────────────────────────────

class ShimmerListingDetail extends StatelessWidget {
  const ShimmerListingDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // Hero image placeholder
          SliverToBoxAdapter(
            child: _box(height: 300, radius: 0),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.s4),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Title
                _box(height: 28, width: double.infinity),
                const SizedBox(height: 10),
                // Chips
                Row(children: [
                  _box(height: 24, width: 90, radius: AppSizes.radiusFull),
                  const SizedBox(width: 8),
                  _box(height: 24, width: 70, radius: AppSizes.radiusFull),
                ]),
                const SizedBox(height: 20),
                // Price row
                Row(children: [
                  _box(height: 36, width: 120),
                  const SizedBox(width: 12),
                  _box(height: 20, width: 80),
                  const Spacer(),
                  _box(height: 32, width: 90, radius: AppSizes.radiusMd),
                ]),
                const SizedBox(height: 20),
                // Stats row
                Row(children: [
                  Expanded(child: _box(height: 64, radius: AppSizes.radiusMd)),
                  const SizedBox(width: 8),
                  Expanded(child: _box(height: 64, radius: AppSizes.radiusMd)),
                  const SizedBox(width: 8),
                  Expanded(child: _box(height: 64, radius: AppSizes.radiusMd)),
                ]),
                const SizedBox(height: 20),
                // Pickup section
                _box(height: 16, width: 120),
                const SizedBox(height: 10),
                _box(height: 64, radius: AppSizes.radiusMd),
                const SizedBox(height: 20),
                // Vendor card
                _box(height: 16, width: 60),
                const SizedBox(height: 10),
                _box(height: 100, radius: AppSizes.radiusMd),
                const SizedBox(height: 20),
                // Description
                _box(height: 16, width: 160),
                const SizedBox(height: 8),
                _box(height: 60, radius: AppSizes.radiusMd),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order detail skeleton ──────────────────────────────────────────────────

class ShimmerOrderDetail extends StatelessWidget {
  const ShimmerOrderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status timeline header
            _box(height: 16, width: 160),
            const SizedBox(height: 16),
            // Timeline dots + lines
            Row(
              children: [
                _circle(24),
                Expanded(child: _box(height: 3)),
                _circle(24),
                Expanded(child: _box(height: 3)),
                _circle(24),
                Expanded(child: _box(height: 3)),
                _circle(24),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _box(height: 10, width: 40),
                const Spacer(),
                _box(height: 10, width: 50),
                const Spacer(),
                _box(height: 10, width: 40),
                const Spacer(),
                _box(height: 10, width: 60),
              ],
            ),
            const SizedBox(height: 28),
            // Item section
            _box(height: 16, width: 60),
            const SizedBox(height: 10),
            _box(height: 72, radius: AppSizes.radiusMd),
            const SizedBox(height: 20),
            // Vendor section
            _box(height: 16, width: 60),
            const SizedBox(height: 10),
            Row(children: [
              _circle(40),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(height: 14, width: 140),
                const SizedBox(height: 6),
                _box(height: 12, width: 100),
              ]),
            ]),
            const SizedBox(height: 24),
            // Info rows
            _box(height: 16, width: 130),
            const SizedBox(height: 12),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _box(height: 13, width: 100),
                    const Spacer(),
                    _box(height: 13, width: 80),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Action button placeholder
            _box(height: AppSizes.buttonHeight, radius: AppSizes.radiusButton),
          ],
        ),
      ),
    );
  }
}

// ─── Admin detail skeleton (vendor/user) ────────────────────────────────────

class ShimmerAdminDetail extends StatelessWidget {
  const ShimmerAdminDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.s4),
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                children: [
                  _circle(72),
                  const SizedBox(height: 12),
                  _box(height: 22, width: 180),
                  const SizedBox(height: 8),
                  _box(height: 14, width: 120),
                  const SizedBox(height: 12),
                  _box(height: 28, width: 100, radius: AppSizes.radiusFull),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            // Info rows
            ...List.generate(
              3,
              (_) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    _box(height: 14, width: 80),
                    const Spacer(),
                    _box(height: 14, width: 120),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.s4),
            // Primary button
            _box(height: AppSizes.buttonHeight, radius: AppSizes.radiusButton),
            const SizedBox(height: 12),
            // Secondary button
            _box(height: AppSizes.buttonHeight, radius: AppSizes.radiusButton),
          ],
        ),
      ),
    );
  }
}

// ─── Vendor order detail skeleton ───────────────────────────────────────────

class ShimmerVendorOrderDetail extends StatelessWidget {
  const ShimmerVendorOrderDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status header card
            _box(height: 110, radius: AppSizes.radiusLg),
            const SizedBox(height: AppSizes.s4),
            // Item section
            _box(height: 16, width: 60),
            const SizedBox(height: 10),
            Row(children: [
              _box(height: 48, width: 48, radius: AppSizes.radiusMd),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _box(height: 14, width: 160),
                const SizedBox(height: 6),
                _box(height: 12, width: 80),
              ]),
              const Spacer(),
              _box(height: 18, width: 70),
            ]),
            const SizedBox(height: AppSizes.s4),
            // Pickup code placeholder
            _box(height: 16, width: 100),
            const SizedBox(height: 10),
            _box(height: 64, radius: AppSizes.radiusMd),
            const SizedBox(height: AppSizes.s6),
            // Action buttons
            _box(height: AppSizes.buttonHeight, radius: AppSizes.radiusButton),
            const SizedBox(height: 12),
            _box(height: AppSizes.buttonHeight, radius: AppSizes.radiusButton),
          ],
        ),
      ),
    );
  }
}
