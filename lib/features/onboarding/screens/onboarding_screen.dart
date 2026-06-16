import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  static const _pages = [_Page0(), _Page1(), _Page2()];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Page view
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: _pages,
            ),
          ),
          // Bottom controls
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              AppSizes.s5,
              AppSizes.s4,
              AppSizes.s5,
              MediaQuery.of(context).padding.bottom + AppSizes.s4,
            ),
            child: Row(
              children: [
                // Dots
                Row(
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _currentPage ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? AppColors.primaryMedium
                            : AppColors.neutral200,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Skip (only on first two pages)
                if (!isLast)
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(width: AppSizes.s2),
                // Next / Get Started
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s5, vertical: AppSizes.s3),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusButton),
                    ),
                  ),
                  child: Text(
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Individual pages ────────────────────────────────────────────────────────

class _Page0 extends StatelessWidget {
  const _Page0();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      gradient: LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primaryMedium],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '🍱',
      headline: 'Discover great food\nnear you',
      body:
          'Browse surplus food from local restaurants, bakeries, and cafes — at up to 70% off. Fresh today, rescued by you.',
      highlights: [
        _Highlight(icon: Icons.location_on_rounded, text: 'Listings near you on a live map'),
        _Highlight(icon: Icons.filter_list_rounded, text: 'Filter by category, price & distance'),
      ],
    );
  }
}

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '📲',
      headline: 'Reserve in seconds,\npay on pickup',
      body:
          'Tap Reserve on any listing. No advance payment needed — just show up during the pickup window and pay cash to the vendor.',
      highlights: [
        _Highlight(icon: Icons.payments_outlined, text: 'Cash on pickup — no card required'),
        _Highlight(icon: Icons.cancel_outlined, text: 'Cancel anytime before your pickup'),
      ],
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      emoji: '✅',
      headline: 'Pick up with your\nQR code',
      body:
          'When you arrive, open your reservation and show the QR code. The vendor scans it and hands over your food. You just rescued a meal!',
      highlights: [
        _Highlight(icon: Icons.qr_code_2_rounded, text: 'One-tap QR display in the app'),
        _Highlight(icon: Icons.eco_rounded, text: 'Every pickup reduces food waste'),
      ],
    );
  }
}

// ─── Shared page layout ──────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.gradient,
    required this.emoji,
    required this.headline,
    required this.body,
    required this.highlights,
  });
  final Gradient gradient;
  final String emoji;
  final String headline;
  final String body;
  final List<_Highlight> highlights;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hero area
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(gradient: gradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji,
                      style: const TextStyle(fontSize: 80, height: 1)),
                  const SizedBox(height: AppSizes.s5),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.s5),
                    child: Text(
                      headline,
                      style: AppTextStyles.h2OnPrimary
                          .copyWith(height: 1.25),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Content area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.s5, AppSizes.s5, AppSizes.s5, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  body,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: AppSizes.s4),
                ...highlights.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.s2),
                      child: h,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryMedium),
        ),
        const SizedBox(width: AppSizes.s3),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall
                  .copyWith(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
