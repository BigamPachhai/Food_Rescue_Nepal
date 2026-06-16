import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSizes.s4,
                MediaQuery.of(context).padding.top + AppSizes.s8,
                AppSizes.s4,
                AppSizes.s6,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryMedium],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSizes.radiusXxl),
                ),
              ),
              child: Column(
                children: [
                  const Text('🥘', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: AppSizes.s3),
                  Text('Join Food Rescue Nepal', style: AppTextStyles.h2OnPrimary),
                  const SizedBox(height: AppSizes.s2),
                  Text(
                    'Great food at up to 70% off — and you\'re helping reduce waste.',
                    style: AppTextStyles.bodySmallOnPrimary.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.s5),
                  // Step indicator
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepDot(filled: true, label: '1', done: false),
                      _StepLine(),
                      _StepDot(filled: false, label: '2', done: false),
                      _StepLine(),
                      _StepDot(filled: false, label: '3', done: false),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s2),
                  Text(
                    'Step 1 of 3 — Choose your role',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.s4),
                    Text('How would you like to use the app?',
                        style: AppTextStyles.h4),
                    const SizedBox(height: AppSizes.s1),
                    Text(
                      'You can switch roles later in Settings.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSizes.s5),
                    _RoleCard(
                      emoji: '🛒',
                      bgColor: AppColors.primarySurface,
                      accentColor: AppColors.primaryMedium,
                      title: "I'm a Customer",
                      subtitle:
                          'Discover discounted food near you and rescue it from waste.',
                      benefits: const [
                        'Browse nearby deals',
                        'Save up to 70%',
                        'Reserve & pickup',
                      ],
                      onTap: () => context.push('/register/customer'),
                    ),
                    const SizedBox(height: AppSizes.s3),
                    _RoleCard(
                      emoji: '🏪',
                      bgColor: AppColors.warningSurface,
                      accentColor: AppColors.warning,
                      title: "I'm a Vendor",
                      subtitle:
                          'List your surplus food, reduce waste, and reach more customers.',
                      benefits: const [
                        'List surplus food',
                        'Earn extra revenue',
                        'Reduce waste',
                      ],
                      onTap: () => context.push('/register/vendor'),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account?',
                            style: AppTextStyles.bodySmall),
                        TextButton(
                          onPressed: () => context.pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.s2),
                          ),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step indicator helpers ────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  const _StepDot({required this.filled, required this.label, required this.done});
  final bool filled;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? Colors.white
            : Colors.white.withValues(alpha: 0.25),
        border: Border.all(
          color: Colors.white.withValues(alpha: filled ? 1.0 : 0.4),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: filled ? AppColors.primaryMedium : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 1.5,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.emoji,
    required this.bgColor,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.onTap,
  });

  final String emoji;
  final Color bgColor;
  final Color accentColor;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.s4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: AppSizes.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  const SizedBox(height: AppSizes.s1),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                  const SizedBox(height: AppSizes.s3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: benefits.map((b) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                        ),
                        child: Text(
                          b,
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.s2),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.neutral400,
            ),
          ],
        ),
      ),
    );
  }
}
