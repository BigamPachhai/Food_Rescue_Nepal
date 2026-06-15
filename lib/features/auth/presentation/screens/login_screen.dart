import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                              onPressed: () => context.go('/forgot-password'),
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
                  child: const Center(
                    child: Text('🥘', style: TextStyle(fontSize: 40)),
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
    return OutlinedButton(
      onPressed: () => context.showSnackBar('Google Sign-In coming soon'),
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
          const Text(
            'G',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDB4437),
            ),
          ),
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
          onPressed: () => context.go('/register'),
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
  {'label': 'Admin', 'email': 'admin@foodrescuenepal.com', 'password': 'Admin@12345!'},
  {'label': 'Customer', 'email': 'customer@test.com', 'password': 'Test@1234!'},
  {'label': 'Vendor ✓', 'email': 'vendor@test.com', 'password': 'Test@1234!'},
  {'label': 'Vendor ⏳', 'email': 'vendor2@test.com', 'password': 'Test@1234!'},
];
