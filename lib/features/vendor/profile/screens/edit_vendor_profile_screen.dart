import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class EditVendorProfileScreen extends ConsumerStatefulWidget {
  const EditVendorProfileScreen({super.key});

  @override
  ConsumerState<EditVendorProfileScreen> createState() =>
      _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState
    extends ConsumerState<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(dioClientProvider).patch('/vendor/profile', data: {
        'businessName': _businessNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        context.showSnackBar('Profile updated!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Business Name',
                controller: _businessNameCtrl,
                prefixIcon: Icons.store_outlined,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Business name'),
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Address',
                controller: _addressCtrl,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) =>
                    Validators.required(v, fieldName: 'Address'),
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Phone',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: Validators.phone,
              ),
              const SizedBox(height: AppSizes.xxl),
              AppButton(
                label: 'Save Changes',
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
