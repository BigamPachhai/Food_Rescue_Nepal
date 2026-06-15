import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.resetPassword, data: {
        'email': widget.email,
        'otp': _otpCtrl.text.trim(),
        'newPassword': _passwordCtrl.text,
      });
      if (!mounted) return;
      context.showSnackBar('Password reset! Please login with your new password.');
      context.go('/login');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Invalid or expired OTP. Please try again.');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.forgotPassword, data: {'email': widget.email});
      if (!mounted) return;
      context.showSnackBar('OTP resent to ${widget.email}');
      _otpCtrl.clear();
      _startCooldown();
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to resend OTP. Please try again.');
    }
    if (mounted) setState(() => _isResending = false);
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
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
        child: Form(
          key: _formKey,
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
                child: const Icon(Icons.key_outlined, color: AppColors.primaryMedium, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Reset Password', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(text: 'Enter the OTP sent to '),
                    TextSpan(
                      text: widget.email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppTextField(
                label: 'OTP Code',
                hint: '6-digit code',
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.pin_outlined,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'OTP is required';
                  if (v.length != 6) return 'OTP must be 6 digits';
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'New Password',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Confirm New Password',
                controller: _confirmCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Reset Password',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
              Center(
                child: _isResending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMedium),
                      )
                    : TextButton(
                        onPressed: _resendCooldown > 0 ? null : _resendOtp,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Resend OTP in ${_resendCooldown}s'
                              : 'Resend OTP',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _resendCooldown > 0
                                ? AppColors.textTertiary
                                : AppColors.primaryMedium,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }
}
