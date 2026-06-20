import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../auth/domain/user_entity.dart';
import '../../../../main.dart' show registerFcmToken;

class TwoFactorLoginScreen extends ConsumerStatefulWidget {
  const TwoFactorLoginScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends ConsumerState<TwoFactorLoginScreen> {
  final _tokenCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = _tokenCtrl.text.trim();
    if (token.length != 6) {
      context.showErrorSnackBar('Enter the 6-digit code from your authenticator app');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final response = await dio.post(
        ApiEndpoints.twoFaVerifyLogin,
        data: {'email': widget.email, 'token': token},
      );
      final raw = response.data as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(raw);

      await DioClient.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      final user = UserEntity.fromJson(authResponse.user.toJson());
      // Update the auth notifier with the authenticated user
      ref.read(authProvider.notifier).setAuthenticated(user);

      if (!mounted) return;
      registerFcmToken(dio);
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Invalid code. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxFormWidth(context)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.security, color: AppColors.primaryMedium, size: 32),
                ),
                const SizedBox(height: 24),
                Text('Two-Factor Authentication', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      const TextSpan(text: 'Open your authenticator app and enter the 6-digit code for '),
                      TextSpan(
                        text: widget.email,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Authenticator Code',
                  hint: '6-digit code',
                  controller: _tokenCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.pin_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Code is required';
                    if (v.length != 6) return 'Code must be 6 digits';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Verify & Sign In',
                  onPressed: _isLoading ? null : _verify,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Use a different account',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryMedium),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
