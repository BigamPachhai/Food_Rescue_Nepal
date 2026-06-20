import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class DataExportRequest {
  final String id, status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  const DataExportRequest({required this.id, required this.status, required this.requestedAt, this.completedAt});
  factory DataExportRequest.fromJson(Map<String, dynamic> j) => DataExportRequest(
        id: j['id'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDING',
        requestedAt: DateTime.tryParse(j['requestedAt'] as String? ?? '') ?? DateTime.now(),
        completedAt: j['completedAt'] != null ? DateTime.tryParse(j['completedAt'] as String) : null,
      );
}

final exportRequestsProvider = FutureProvider<List<DataExportRequest>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.myDataExports);
  final raw = res.data as Map<String, dynamic>;
  final data = raw['data'];
  final items = data is List ? data : <dynamic>[];
  return items.map((e) => DataExportRequest.fromJson(e as Map<String, dynamic>)).toList();
});

class GdprScreen extends ConsumerStatefulWidget {
  const GdprScreen({super.key});

  @override
  ConsumerState<GdprScreen> createState() => _GdprScreenState();
}

class _GdprScreenState extends ConsumerState<GdprScreen> {
  bool _requesting = false;
  bool _deleting = false;

  Future<void> _requestExport() async {
    setState(() => _requesting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.requestDataExport);
      ref.invalidate(exportRequestsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export requested. You\'ll be notified when it\'s ready.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _requesting = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('This will permanently anonymize all your personal data. This cannot be undone.\n\nYour order history will be retained anonymously for legal compliance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.delete(ApiEndpoints.deleteAccount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted. Logging out…')));
        // Navigate to login — actual logout handled by auth provider
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final exportsAsync = ref.watch(exportRequestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeader(title: 'Your Data Rights', icon: Icons.privacy_tip_outlined),
            const SizedBox(height: 8),
            const Text('Under GDPR and applicable data protection laws, you have the right to access and export your personal data, or request its deletion.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 24),

            const _SectionHeader(title: 'Export My Data', icon: Icons.download),
            const SizedBox(height: 8),
            const Text('Request a copy of all personal data we hold about you (profile, orders, reviews).', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: const Text('Request Data Export'),
                onPressed: _requesting ? null : _requestExport,
              ),
            ),
            const SizedBox(height: 16),
            exportsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) => requests.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Previous Requests', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        ...requests.map((r) => _ExportTile(request: r)),
                      ],
                    ),
            ),
            const Divider(height: 40),

            const _SectionHeader(title: 'Delete My Account', icon: Icons.delete_forever, color: Colors.red),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
              child: const Text('Warning: Account deletion permanently anonymizes all your personal data. This action cannot be reversed.', style: TextStyle(fontSize: 13, color: Colors.red)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete My Account', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                onPressed: _deleting ? null : _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  const _SectionHeader({required this.title, required this.icon, this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        ],
      );
}

class _ExportTile extends StatelessWidget {
  final DataExportRequest request;
  const _ExportTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == 'PENDING';
    final isDone = request.status == 'COMPLETED';
    return ListTile(
      dense: true,
      leading: Icon(isDone ? Icons.check_circle : isPending ? Icons.hourglass_empty : Icons.error, color: isDone ? Colors.green : isPending ? Colors.orange : Colors.red),
      title: Text('Export ${request.id.substring(0, 8)}…'),
      subtitle: Text(_fmt(request.requestedAt)),
      trailing: Text(request.status, style: TextStyle(fontSize: 11, color: isDone ? Colors.green : Colors.orange)),
    );
  }

  String _fmt(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
