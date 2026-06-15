import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../domain/auth_state.dart';
import '../../../../main.dart' show registerFcmToken;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  void _showRolePicker(BuildContext context, String firebaseIdToken) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoogleRolePickerSheet(firebaseIdToken: firebaseIdToken),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        context.showErrorSnackBar(next.message);
      } else if (next is AuthAuthenticated) {
        registerFcmToken(ref.read(dioClientProvider));
        final user = next.user;
        if (user.isAdmin) {
          context.go('/admin/dashboard');
        } else if (user.isVendor) {
          context.go('/vendor/dashboard');
        } else {
          context.go('/customer/home');
        }
      } else if (next is AuthGoogleNewUser) {
        _showRolePicker(context, next.firebaseIdToken);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.s4, AppSizes.s6, AppSizes.s4, AppSizes.s4,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Welcome back', style: AppTextStyles.h2),
                          const SizedBox(height: AppSizes.s1),
                          Text(
                            'Sign in to continue rescuing food',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSizes.s6),
                          AppTextField(
                            label: 'Email address',
                            hint: 'you@example.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: Validators.email,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSizes.s3),
                          AppTextField(
                            label: 'Password',
                            controller: _passwordCtrl,
                            isPassword: true,
                            prefixIcon: Icons.lock_outline_rounded,
                            validator: Validators.password,
                            textInputAction: TextInputAction.done,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.s2,
                                  vertical: AppSizes.s2,
                                ),
                              ),
                              child: Text(
                                'Forgot password?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primaryMedium,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSizes.s2),
                          AppButton(
                            label: 'Sign In',
                            onPressed: isLoading ? null : _login,
                            isLoading: isLoading,
                          ),
                          const SizedBox(height: AppSizes.s5),
                          _buildDivider(),
                          const SizedBox(height: AppSizes.s5),
                          _buildGoogleButton(),
                          const SizedBox(height: AppSizes.s6),
                          _buildRegisterRow(),
                          if (kDebugMode) ...[
                            const SizedBox(height: AppSizes.s6),
                            _buildDevPanel(),
                          ],
                          const SizedBox(height: AppSizes.s4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      height: Responsive.authHeaderHeight(context),
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
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.s3),
                Text('Food Rescue Nepal', style: AppTextStyles.h3OnPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.s3),
          child: Text('or continue with', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildGoogleButton() {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    return OutlinedButton(
      onPressed: isLoading ? null : () => ref.read(authProvider.notifier).googleSignIn(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusButton),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/images/google_logo.svg', width: 20, height: 20),
          const SizedBox(width: AppSizes.s2),
          Text(
            'Continue with Google',
            style: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account?", style: AppTextStyles.bodySmall),
        TextButton(
          onPressed: () => context.push('/register'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.s2),
          ),
          child: Text(
            'Register',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primaryMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDevPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.s3),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚡ Dev Quick Login',
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSizes.s2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _devAccounts.map((a) {
              return ActionChip(
                label: Text(
                  a['label']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppColors.primaryMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  side: BorderSide.none,
                ),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  _emailCtrl.text = a['email']!;
                  _passwordCtrl.text = a['password']!;
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

const _devAccounts = [
  {'label': 'Customer', 'email': 'customer@test.com', 'password': 'Test@1234!'},
  {'label': 'Vendor ✓', 'email': 'vendor@test.com', 'password': 'Test@1234!'},
  {'label': 'Vendor ⏳', 'email': 'vendor2@test.com', 'password': 'Test@1234!'},
];

class _GoogleRolePickerSheet extends ConsumerWidget {
  const _GoogleRolePickerSheet({required this.firebaseIdToken});
  final String firebaseIdToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXxl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.s4, AppSizes.s3, AppSizes.s4,
        AppSizes.s4 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            ),
          ),
          const SizedBox(height: AppSizes.s5),
          Text('How will you use the app?', style: AppTextStyles.h3),
          const SizedBox(height: AppSizes.s2),
          Text(
            'Choose your role to complete sign-in',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.s5),
          _RoleTile(
            emoji: '🛒',
            title: 'Customer',
            subtitle: 'Browse & reserve discounted food near you',
            bgColor: AppColors.primarySurface,
            accentColor: AppColors.primaryMedium,
            onTap: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).completeGoogleSignIn(firebaseIdToken, 'CUSTOMER');
            },
          ),
          const SizedBox(height: AppSizes.s3),
          _RoleTile(
            emoji: '🏪',
            title: 'Vendor',
            subtitle: 'List surplus food and reach more customers',
            bgColor: AppColors.warningSurface,
            accentColor: AppColors.warning,
            onTap: () {
              Navigator.pop(context);
              // Vendor needs full registration with business details
              context.push('/register/vendor');
            },
          ),
          const SizedBox(height: AppSizes.s4),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.accentColor,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color accentColor;
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
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
            ),
            const SizedBox(width: AppSizes.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h4),
                  const SizedBox(height: AppSizes.s1),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: accentColor),
          ],
        ),
      ),
    );
  }
}
