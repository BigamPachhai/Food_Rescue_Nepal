import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class VendorGalleryScreen extends StatefulWidget {
  const VendorGalleryScreen({super.key});

  @override
  State<VendorGalleryScreen> createState() => _VendorGalleryScreenState();
}

class _VendorGalleryScreenState extends State<VendorGalleryScreen> {
  final List<_GalleryItem> _items = [
    const _GalleryItem('Store Front', 'store'),
    const _GalleryItem('Bakery Section', 'bakery'),
    const _GalleryItem('Fresh Produce', 'produce'),
    const _GalleryItem('Prepared Meals', 'meals'),
    const _GalleryItem('Team Photo', 'team'),
    const _GalleryItem('Special Packaging', 'pack'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Store Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_rounded),
            onPressed: _addPhoto,
          ),
        ],
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            _StatPill(Icons.photo_library_rounded, '${_items.length} Photos'),
            const SizedBox(width: 8),
            const _StatPill(Icons.visibility_rounded, '2.4k Views'),
            const SizedBox(width: 8),
            const _StatPill(Icons.thumb_up_rounded, '142 Likes'),
          ]),
        ),
        Expanded(
          child: _items.isEmpty
              ? _EmptyGallery(onAdd: _addPhoto)
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _items.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return GestureDetector(
                        onTap: _addPhoto,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryMedium.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryMedium.withValues(alpha: 0.3), style: BorderStyle.solid),
                          ),
                          child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_rounded, color: AppColors.primaryMedium, size: 28),
                            SizedBox(height: 4),
                            Text('Add', style: TextStyle(color: AppColors.primaryMedium, fontSize: 11)),
                          ]),
                        ),
                      );
                    }
                    final item = _items[i - 1];
                    return GestureDetector(
                      onTap: () => _viewPhoto(context, item, i - 1),
                      onLongPress: () => _showOptions(context, i - 1),
                      child: Stack(fit: StackFit.expand, children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: _colorForTag(item.tag),
                            child: Icon(_iconForTag(item.tag), color: Colors.white.withValues(alpha: 0.6), size: 36),
                          ),
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                            ),
                            child: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ]),
                    );
                  },
                ),
        ),
        _GalleryTips(),
      ]),
    );
  }

  Color _colorForTag(String tag) {
    switch (tag) {
      case 'bakery': return Colors.orange;
      case 'produce': return Colors.green;
      case 'meals': return Colors.purple;
      case 'team': return Colors.blue;
      case 'pack': return Colors.teal;
      default: return AppColors.primaryMedium;
    }
  }

  IconData _iconForTag(String tag) {
    switch (tag) {
      case 'bakery': return Icons.bakery_dining_rounded;
      case 'produce': return Icons.eco_rounded;
      case 'meals': return Icons.restaurant_rounded;
      case 'team': return Icons.people_rounded;
      case 'pack': return Icons.inventory_2_rounded;
      default: return Icons.store_rounded;
    }
  }

  void _addPhoto([ BuildContext? ctx]) {
    final context = ctx ?? this.context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add Photo', style: AppTextStyles.h5),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Camera opened'))); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery opened'))); },
          ),
        ]),
      ),
    );
  }

  void _viewPhoto(BuildContext context, _GalleryItem item, int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(height: 200, color: _colorForTag(item.tag), child: Center(child: Icon(_iconForTag(item.tag), color: Colors.white, size: 64))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(child: Text(item.label, style: AppTextStyles.h5)),
              IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.red), onPressed: () { setState(() => _items.removeAt(index)); Navigator.pop(context); }),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showOptions(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.star_rounded, color: Colors.amber), title: const Text('Set as Cover Photo'), onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover photo updated'))); }),
        ListTile(leading: const Icon(Icons.delete_outline_rounded, color: Colors.red), title: const Text('Delete Photo'), onTap: () { setState(() => _items.removeAt(index)); Navigator.pop(context); }),
      ]),
    );
  }
}

class _GalleryItem {
  final String label, tag;
  const _GalleryItem(this.label, this.tag);
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
