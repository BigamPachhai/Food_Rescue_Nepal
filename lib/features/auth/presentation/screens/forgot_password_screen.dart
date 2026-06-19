import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/utils/responsive.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    final email = _emailCtrl.text.trim();
    final dio = ref.read(dioClientProvider);

    // Retry once on timeout — the server may be cold-starting (Render free tier).
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        await dio.post(
          ApiEndpoints.forgotPassword,
          data: {'email': email},
          options: Options(receiveTimeout: const Duration(seconds: 60)),
        );
        if (!mounted) return;
        context.push('/reset-password', extra: {'email': email});
        return;
      } on DioException catch (e) {
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;

        if (isTimeout && attempt == 0) {
          // First attempt timed out — server may be waking up, try once more.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Server is starting up, retrying…'),
                duration: Duration(seconds: 3),
              ),
            );
          }
          continue;
        }

        if (mounted) {
          final msg = e.error is AppException
              ? (e.error! as AppException).message
              : isTimeout
                  ? 'Connection timed out. Please try again in a moment.'
                  : 'Failed to send OTP. Please try again.';
          context.showErrorSnackBar(msg);
        }
        break;
      } catch (e) {
        if (mounted) context.showErrorSnackBar('Failed to send OTP. Please try again.');
        break;
      }
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
                child: const Icon(Icons.lock_reset, color: AppColors.primaryMedium, size: 32),
              ),
              const SizedBox(height: 24),
              Text('Forgot Password?', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Enter the email address linked to your account. We\'ll send you a 6-digit OTP to reset your password.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 32),
              AppTextField(
                label: 'Email Address',
                hint: 'your@email.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: Validators.email,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Send OTP',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Back to Login',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryMedium),
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
