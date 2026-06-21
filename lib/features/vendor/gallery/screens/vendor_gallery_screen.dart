import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/dio_client.dart';

class VendorGalleryScreen extends ConsumerStatefulWidget {
  const VendorGalleryScreen({super.key});

  @override
  ConsumerState<VendorGalleryScreen> createState() => _VendorGalleryScreenState();
}

class _VendorGalleryScreenState extends ConsumerState<VendorGalleryScreen> {
  final List<String> _imageUrls = [];
  bool _uploading = false;

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85, maxWidth: 1080);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final dio = ref.read(dioClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: 'gallery.jpg'),
      });
      final res = await dio.post(ApiEndpoints.uploadImage, data: formData);
      final url = (res.data as Map<String, dynamic>)['data']?['url'] as String?;
      if (url != null) setState(() => _imageUrls.add(url));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo added')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
    if (mounted) setState(() => _uploading = false);
  }

  void _addPhoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Photo', style: AppTextStyles.h5),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () { Navigator.pop(ctx); _pickAndUpload(ImageSource.camera); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () { Navigator.pop(ctx); _pickAndUpload(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  void _deletePhoto(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _viewPhoto(BuildContext context, String url, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.network(url, height: 240, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () { Navigator.pop(context); _deletePhoto(index); },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Store Gallery'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(icon: const Icon(Icons.add_photo_alternate_rounded), onPressed: _addPhoto),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _StatPill(Icons.photo_library_rounded, '${_imageUrls.length} Photos'),
          ]),
        ),
        Expanded(
          child: _imageUrls.isEmpty
              ? _EmptyGallery(onAdd: _addPhoto)
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _imageUrls.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return GestureDetector(
                        onTap: _addPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryMedium.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3)),
                          ),
                          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_rounded, color: AppColors.primaryMedium, size: 28),
                            SizedBox(height: 4),
                            Text('Add', style: TextStyle(color: AppColors.primaryMedium, fontSize: 11)),
                          ]),
                        ),
                      );
                    }
                    final url = _imageUrls[i - 1];
                    return GestureDetector(
                      onTap: () => _viewPhoto(context, url, i - 1),
                      onLongPress: () => _deletePhoto(i - 1),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        _GalleryTips(),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.primaryMedium),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.caption),
    ]),
  );
}

class _EmptyGallery extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGallery({required this.onAdd});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.photo_library_rounded, size: 64, color: Colors.grey),
    const SizedBox(height: 12),
    Text('No photos yet', style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary)),
    const SizedBox(height: 4),
    Text('Add photos to showcase your store', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
    const SizedBox(height: 16),
    ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_photo_alternate_rounded), label: const Text('Add First Photo'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMedium, foregroundColor: Colors.white)),
  ]));
}

class _GalleryTips extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(children: [
      const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 16),
      const SizedBox(width: 6),
      Expanded(child: Text('Listings with photos get 3× more views. Add clear, well-lit images!', style: AppTextStyles.caption)),
    ]),
  );
}
