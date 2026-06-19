import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/vendor_listings_provider.dart';

enum ListingFormMode { add, edit }

class AddEditListingScreen extends ConsumerStatefulWidget {
  const AddEditListingScreen({
    super.key,
    required this.mode,
    this.listingId,
  });
  final ListingFormMode mode;
  final String? listingId;

  @override
  ConsumerState<AddEditListingScreen> createState() =>
      _AddEditListingScreenState();
}

class _AddEditListingScreenState extends ConsumerState<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _discountedPriceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  String _category = 'Restaurant';
  DateTime _pickupStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _pickupEnd = DateTime.now().add(const Duration(hours: 4));
  DateTime? _expiryTime;
  final List<String> _imageUrls = [];
  final List<File> _pendingImages = [];
  bool _isLoading = false;
  final Set<String> _dietaryTags = {};

  static const _allDietaryTags = [
    ('VEGAN', 'Vegan', Icons.eco_rounded),
    ('VEGETARIAN', 'Vegetarian', Icons.grass_rounded),
    ('HALAL', 'Halal', Icons.verified_rounded),
    ('GLUTEN_FREE', 'Gluten Free', Icons.no_meals_rounded),
    ('DAIRY_FREE', 'Dairy Free', Icons.no_drinks_rounded),
    ('ORGANIC', 'Organic', Icons.nature_rounded),
  ];

  final _categories = [
    'Surprise Bag',
    'Restaurant',
    'Cafe',
    'Bakery',
    'Grocery',
    'Sweets',
    'Other',
  ];

  static const _categoryEnumMap = {
    'Surprise Bag': 'SURPRISE_BAG',
    'Restaurant': 'RESTAURANT',
    'Cafe': 'CAFE',
    'Bakery': 'BAKERY',
    'Grocery': 'GROCERY',
    'Sweets': 'SWEETS',
    'Other': 'OTHER',
  };

  static const _enumToCategoryMap = {
    'SURPRISE_BAG': 'Surprise Bag',
    'RESTAURANT': 'Restaurant',
    'CAFE': 'Cafe',
    'BAKERY': 'Bakery',
    'GROCERY': 'Grocery',
    'SWEETS': 'Sweets',
    'OTHER': 'Other',
  };

  String _normalizeCategory(String cat) {
    return _enumToCategoryMap[cat.toUpperCase()] ?? 'Other';
  }

  String _categoryToEnum(String displayCategory) {
    return _categoryEnumMap[displayCategory] ?? 'OTHER';
  }

  int get _discountPercent {
    final orig = int.tryParse(_originalPriceCtrl.text) ?? 0;
    final disc = int.tryParse(_discountedPriceCtrl.text) ?? 0;
    if (orig == 0 || disc >= orig) return 0;
    return (((orig - disc) / orig) * 100).round();
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == ListingFormMode.edit && widget.listingId != null) {
      _loadExisting();
    }
    _originalPriceCtrl.addListener(() => setState(() {}));
    _discountedPriceCtrl.addListener(() => setState(() {}));
  }

  Future<void> _loadExisting() async {
    final listing =
        await ref.read(vendorListingDetailProvider(widget.listingId!).future);
    _nameCtrl.text = listing.name;
    _descCtrl.text = listing.description ?? '';
    _conditionCtrl.text = listing.conditionNotes ?? '';
    _originalPriceCtrl.text = (listing.originalPrice ~/ 100).toString();
    _discountedPriceCtrl.text = (listing.discountedPrice ~/ 100).toString();
    _qtyCtrl.text = listing.quantity.toString();
    setState(() {
      _category = _normalizeCategory(listing.category);
      _pickupStart = listing.pickupStart;
      _pickupEnd = listing.pickupEnd;
      _expiryTime = listing.expiryTime;
      _imageUrls.addAll(listing.imageUrls);
      _dietaryTags.addAll(listing.dietaryTags);
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _conditionCtrl.dispose();
    _originalPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imageUrls.length + _pendingImages.length >= 3) {
      context.showSnackBar('Maximum 3 images allowed');
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;

    final ext = picked.path.toLowerCase();
    final validExt = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    if (!validExt) {
      if (mounted) context.showSnackBar('Only JPG, PNG, or WEBP images are allowed');
      return;
    }

    final file = File(picked.path);
    final sizeBytes = await file.length();
    if (sizeBytes > 5 * 1024 * 1024) {
      if (mounted) context.showSnackBar('Image must be under 5 MB');
      return;
    }

    setState(() => _pendingImages.add(file));
  }

  Future<List<String>> _uploadPendingImages() async {
    final dio = ref.read(dioClientProvider);
    final futures = _pendingImages.map((file) async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final response = await dio.post(ApiEndpoints.uploadImage, data: formData);
      final responseData = response.data as Map<String, dynamic>;
      return (responseData['data'] as Map<String, dynamic>)['url'] as String;
    });
    return Future.wait(futures);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imageUrls.isEmpty && _pendingImages.isEmpty) {
      context.showSnackBar('Please add at least one image');
      return;
    }
    final origVal = int.tryParse(_originalPriceCtrl.text) ?? 0;
    final discVal = int.tryParse(_discountedPriceCtrl.text) ?? 0;
    if (discVal >= origVal) {
      context.showSnackBar('Discounted price must be less than original price');
      return;
    }
    if (!_pickupEnd.isAfter(_pickupStart)) {
      context.showSnackBar('Pickup end time must be after pickup start time');
      return;
    }
    if (_expiryTime != null && _expiryTime!.isBefore(_pickupEnd)) {
      context.showSnackBar('Expiry time must be after pickup end time');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final newUrls = await _uploadPendingImages();
      final allUrls = [..._imageUrls, ...newUrls];

      final originalPaisa =
          (double.parse(_originalPriceCtrl.text) * 100).round();
      final discountedPaisa =
          (double.parse(_discountedPriceCtrl.text) * 100).round();

      final payload = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _categoryToEnum(_category),
        'originalPrice': originalPaisa,
        'discountedPrice': discountedPaisa,
        'quantity': int.parse(_qtyCtrl.text),
        'pickupStart': _pickupStart.toIso8601String(),
        'pickupEnd': _pickupEnd.toIso8601String(),
        'imageUrls': allUrls,
        if (_conditionCtrl.text.trim().isNotEmpty)
          'conditionNotes': _conditionCtrl.text.trim(),
        if (_expiryTime != null) 'expiryTime': _expiryTime!.toIso8601String(),
        if (_dietaryTags.isNotEmpty) 'dietaryTags': _dietaryTags.toList(),
      };

      final dio = ref.read(dioClientProvider);
      if (widget.mode == ListingFormMode.add) {
        await dio.post(ApiEndpoints.createListing, data: payload);
      } else {
        await dio.patch(
          ApiEndpoints.vendorListingById(widget.listingId!),
          data: payload,
        );
      }

      ref.invalidate(vendorListingsProvider);
      if (mounted) {
        context.showSnackBar(widget.mode == ListingFormMode.add
            ? 'Listing created!'
            : 'Listing updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickExpiryTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _expiryTime ?? now.add(const Duration(hours: 6)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_expiryTime ?? now.add(const Duration(hours: 6))),
    );
    if (time == null) return;
    setState(() {
      _expiryTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _pickupStart : _pickupEnd,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? _pickupStart : _pickupEnd),
    );
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _pickupStart = dt;
      } else {
        _pickupEnd = dt;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == ListingFormMode.add
        ? 'Add Listing'
        : 'Edit Listing';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Food Name',
                controller: _nameCtrl,
                prefixIcon: Icons.fastfood_outlined,
                validator: (v) => Validators.required(v, fieldName: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSizes.lg),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  filled: true,
                  fillColor: AppColors.primarySurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(Icons.category_outlined,
                      color: AppColors.textSecondary),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Icon(
                        c == 'Surprise Bag' ? Icons.card_giftcard_rounded : Icons.fastfood_rounded,
                        size: 16,
                        color: c == 'Surprise Bag' ? AppColors.accentAmber : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(c),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              // Surprise Bag hint banner
              if (_category == 'Surprise Bag') ...[
                const SizedBox(height: AppSizes.md),
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.accentAmber),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Surprise Bag selected', style: AppTextStyles.label.copyWith(color: AppColors.accentAmber, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              'Customers won\'t know exactly what\'s inside — just the category and value. Surprise Bags build excitement and sell out fast!',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 500,
                counterText: '',
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_descCtrl.text.length}/500',
                  style: AppTextStyles.caption.copyWith(
                    color: _descCtrl.text.length > 450 ? AppColors.warning : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              // Dietary tags
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Dietary Tags', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allDietaryTags.map((tag) {
                  final selected = _dietaryTags.contains(tag.$1);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(tag.$3, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(tag.$2),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      if (selected) {
                        _dietaryTags.remove(tag.$1);
                      } else {
                        _dietaryTags.add(tag.$1);
                      }
                    }),
                    selectedColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    showCheckmark: false,
                    side: BorderSide(color: selected ? AppColors.primaryMedium : AppColors.border),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Original Price (NPR)',
                      controller: _originalPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefixIcon: Icons.payments_outlined,
                      validator: Validators.positiveNumber,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Discounted (NPR)',
                      controller: _discountedPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      prefixIcon: Icons.discount_outlined,
                      validator: Validators.positiveNumber,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              if (_discountPercent > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMedium,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_discountPercent% OFF',
                          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Builder(builder: (context) {
                        final orig = int.tryParse(_originalPriceCtrl.text) ?? 0;
                        final disc = int.tryParse(_discountedPriceCtrl.text) ?? 0;
                        final saved = orig - disc;
                        if (saved <= 0) return const SizedBox.shrink();
                        return Text(
                          'Customer saves NPR $saved',
                          style: AppTextStyles.caption.copyWith(color: AppColors.success),
                        );
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Quantity',
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefixIcon: Icons.inventory_2_outlined,
                validator: Validators.positiveInteger,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSizes.lg),
              // Pickup times
              Row(
                children: [
                  Expanded(
                    child: _DateTimeTile(
                      label: 'Pickup Start',
                      dateTime: _pickupStart,
                      onTap: () => _pickDateTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateTimeTile(
                      label: 'Pickup End',
                      dateTime: _pickupEnd,
                      onTap: () => _pickDateTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              // Expiry time
              GestureDetector(
                onTap: _pickExpiryTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 20,
                        color: _expiryTime != null ? AppColors.warning : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Food Expiry Time (optional)', style: AppTextStyles.caption),
                            if (_expiryTime != null)
                              Text(
                                '${_expiryTime!.day}/${_expiryTime!.month}/${_expiryTime!.year}  ${_expiryTime!.hour.toString().padLeft(2, '0')}:${_expiryTime!.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w500),
                              )
                            else
                              Text('Tap to set expiry time', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      if (_expiryTime != null)
                        GestureDetector(
                          onTap: () => setState(() => _expiryTime = null),
                          child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              AppTextField(
                label: 'Condition Notes (optional)',
                hint: 'e.g. Freshly baked, no preservatives, best before pickup',
                controller: _conditionCtrl,
                prefixIcon: Icons.info_outline,
                maxLines: 2,
              ),
              const SizedBox(height: AppSizes.lg),
              Text('Photos', style: AppTextStyles.h5),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Existing images
                  ..._imageUrls.asMap().entries.map((e) => _ImageSlot(
                        imageUrl: e.value,
                        onRemove: () =>
                            setState(() => _imageUrls.removeAt(e.key)),
                      )),
                  // Pending images
                  ..._pendingImages.asMap().entries.map((e) => _ImageSlot(
                        file: e.value,
                        onRemove: () =>
                            setState(() => _pendingImages.removeAt(e.key)),
                      )),
                  // Add button
                  if (_imageUrls.length + _pendingImages.length < 3)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primaryLight,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.primarySurface,
                        ),
                        child: const Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.primaryMedium, size: 28),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              AppButton(
                label: widget.mode == ListingFormMode.add
                    ? 'Save Listing'
                    : 'Update Listing',
                onPressed: _isLoading ? null : _save,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.dateTime,
    required this.onTap,
  });
  final String label;
  final DateTime dateTime;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 14, color: AppColors.primaryMedium),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryMedium),
                  ),
                ),
              ],
            ),
            Text(
              '${dateTime.day}/${dateTime.month}/${dateTime.year}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({this.imageUrl, this.file, required this.onRemove});
  final String? imageUrl;
  final File? file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: file != null
                  ? FileImage(file!) as ImageProvider
                  : NetworkImage(imageUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
