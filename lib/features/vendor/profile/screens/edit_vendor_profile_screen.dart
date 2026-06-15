import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/error_view.dart';
import '../providers/vendor_profile_provider.dart';

class EditVendorProfileScreen extends ConsumerStatefulWidget {
  const EditVendorProfileScreen({super.key});

  @override
  ConsumerState<EditVendorProfileScreen> createState() => _EditVendorProfileScreenState();
}

class _EditVendorProfileScreenState extends ConsumerState<EditVendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameCtrl = TextEditingController();
  final _businessTypeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  File? _pickedLogo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final async = ref.read(vendorProfileProvider);
    async.whenData((profile) {
      _businessNameCtrl.text = profile.businessName;
      _businessTypeCtrl.text = profile.businessType;
      _descriptionCtrl.text = profile.description ?? '';
      _addressCtrl.text = profile.address;
    });
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _businessTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 512);
    if (picked == null) return;
    setState(() {
      _pickedLogo = File(picked.path);
      _isUploadingLogo = true;
    });
    try {
      final dio = ref.read(dioClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'logo.jpg'),
      });
      await dio.post('/vendors/logo', data: formData);
      if (mounted) context.showSnackBar('Logo updated!');
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Failed to upload logo');
    }
    if (mounted) setState(() => _isUploadingLogo = false);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.patch('/vendors/profile', data: {
        'businessName': _businessNameCtrl.text.trim(),
        'businessType': _businessTypeCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      ref.invalidate(vendorProfileProvider);
      if (mounted) {
        context.showSnackBar('Store profile updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(vendorProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store Profile')),
      body: profileAsync.when(
        data: (profile) => _buildForm(profile),
        loading: () => _buildForm(null),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(vendorProfileProvider),
        ),
      ),
    );
  }

  Widget _buildForm(VendorProfile? profile) {
    final logoUrl = _pickedLogo != null ? null : profile?.logoUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _pickedLogo != null
                        ? FileImage(_pickedLogo!) as ImageProvider
                        : (logoUrl != null ? CachedNetworkImageProvider(logoUrl) : null),
                    child: (_pickedLogo == null && logoUrl == null)
                        ? const Icon(Icons.store, size: 48, color: Colors.white)
                        : null,
                  ),
                  if (_isUploadingLogo)
                    const Positioned.fill(
                      child: CircularProgressIndicator(),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingLogo ? null : _pickLogo,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap to change logo',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 28),
            Text('Business Details', style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Business Name',
              controller: _businessNameCtrl,
              prefixIcon: Icons.store_outlined,
              validator: (v) => Validators.required(v, fieldName: 'Business name'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Business Type',
              hint: 'e.g. Restaurant, Cafe, Bakery',
              controller: _businessTypeCtrl,
              prefixIcon: Icons.category_outlined,
              validator: (v) => Validators.required(v, fieldName: 'Business type'),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Description',
              hint: 'Tell customers about your business...',
              controller: _descriptionCtrl,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: AppSizes.lg),
            Text('Location & Contact', style: AppTextStyles.h6.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Address',
              controller: _addressCtrl,
              prefixIcon: Icons.location_on_outlined,
              validator: (v) => Validators.required(v, fieldName: 'Address'),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Opening Hours', style: AppTextStyles.caption),
                      Text('Coming soon', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            AppButton(
              label: 'Save Changes',
              onPressed: _isSaving ? null : _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}
