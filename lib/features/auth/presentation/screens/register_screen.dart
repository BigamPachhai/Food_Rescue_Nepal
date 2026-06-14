import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_models.dart';
import '../../domain/auth_state.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final String role;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _businessType = 'Restaurant';
  LatLng _markerPosition = const LatLng(27.7172, 85.3240);

  final _businessTypes = ['Restaurant', 'Cafe', 'Bakery', 'Grocery', 'Sweets', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get isVendor => widget.role == 'VENDOR';

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final request = RegisterRequest(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: widget.role,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      businessName: isVendor ? _businessNameCtrl.text.trim() : null,
      businessType: isVendor ? _businessType : null,
      address: isVendor ? _addressCtrl.text.trim() : null,
      lat: isVendor ? _markerPosition.latitude : null,
      lng: isVendor ? _markerPosition.longitude : null,
    );
    await ref.read(authProvider.notifier).register(request);
    // Router refreshListenable handles redirect
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        context.showErrorSnackBar(next.message);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isVendor ? 'Register Business' : 'Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) => Validators.required(v, fieldName: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: Validators.email,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Password',
                controller: _passwordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: Validators.password,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordCtrl,
                isPassword: true,
                prefixIcon: Icons.lock_outline,
                validator: (v) => Validators.confirmPassword(v, _passwordCtrl.text),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Phone (optional)',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: Validators.phone,
                textInputAction: isVendor ? TextInputAction.next : TextInputAction.done,
              ),
              if (isVendor) ...[
                const SizedBox(height: AppSizes.xxl),
                Text('Business Info', style: AppTextStyles.h5.copyWith(color: AppColors.primaryMedium)),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Business Name',
                  controller: _businessNameCtrl,
                  prefixIcon: Icons.store_outlined,
                  validator: (v) => Validators.required(v, fieldName: 'Business name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSizes.lg),
                DropdownButtonFormField<String>(
                  initialValue: _businessType,
                  decoration: InputDecoration(
                    labelText: 'Business Type',
                    filled: true,
                    fillColor: AppColors.primarySurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.category_outlined, color: AppColors.textSecondary),
                  ),
                  items: _businessTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _businessType = v!),
                ),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Business Address',
                  controller: _addressCtrl,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (v) => Validators.required(v, fieldName: 'Address'),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSizes.lg),
                Text('Pin your location', style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _markerPosition,
                        initialZoom: 13,
                        onTap: (_, point) {
                          setState(() => _markerPosition = point);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.foodrescue.nepal',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _markerPosition,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_pin,
                                color: AppColors.primaryMedium,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on map to move marker',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: 32),
              AppButton(
                label: isVendor ? 'Register Business' : 'Create Account',
                onPressed: isLoading ? null : _register,
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
