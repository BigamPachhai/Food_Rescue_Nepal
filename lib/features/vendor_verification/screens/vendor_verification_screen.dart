import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class VerificationDoc {
  final String id, docType, status;
  final String? rejectionReason;
  final DateTime uploadedAt;
  const VerificationDoc({required this.id, required this.docType, required this.status, this.rejectionReason, required this.uploadedAt});
  factory VerificationDoc.fromJson(Map<String, dynamic> j) => VerificationDoc(
        id: j['id'] as String? ?? '',
        docType: j['docType'] as String? ?? '',
        status: j['status'] as String? ?? 'PENDING',
        rejectionReason: j['rejectionReason'] as String?,
        uploadedAt: DateTime.tryParse(j['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

final verificationDocsProvider = FutureProvider<List<VerificationDoc>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.myVerificationDocs);
  final raw = res.data as Map<String, dynamic>;
  final data = raw['data'];
  final items = data is List ? data : <dynamic>[];
  return items.map((e) => VerificationDoc.fromJson(e as Map<String, dynamic>)).toList();
});

const _docTypes = ['BUSINESS_REGISTRATION', 'TAX_CERTIFICATE', 'FOOD_LICENSE', 'IDENTITY_PROOF', 'OTHER'];

class VendorVerificationScreen extends ConsumerStatefulWidget {
  const VendorVerificationScreen({super.key});

  @override
  ConsumerState<VendorVerificationScreen> createState() => _VendorVerificationScreenState();
}

class _VendorVerificationScreenState extends ConsumerState<VendorVerificationScreen> {
  String? _selectedDocType;
  final _urlCtrl = TextEditingController();
  bool _uploading = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    if (_selectedDocType == null || _urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a document type and provide the file URL')));
      return;
    }
    setState(() => _uploading = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.uploadVerificationDoc, data: {
        'docType': _selectedDocType,
        'fileUrl': _urlCtrl.text.trim(),
      });
      ref.invalidate(verificationDocsProvider);
      _urlCtrl.clear();
      setState(() => _selectedDocType = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document submitted for review')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(verificationDocsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Business Verification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(child: Text('Verified vendors get a badge and higher listing visibility.', style: TextStyle(fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Upload Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedDocType,
              decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder()),
              items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ')))).toList(),
              onChanged: (v) => setState(() => _selectedDocType = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Document URL',
                hintText: 'https://…',
                border: OutlineInputBorder(),
                helperText: 'Upload your file to a storage service and paste the link here',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Submit Document'),
                onPressed: _uploading ? null : _upload,
              ),
            ),
            const SizedBox(height: 32),
            const Text('Submitted Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
              data: (docs) => docs.isEmpty
                  ? Text('No documents submitted yet', style: TextStyle(color: Colors.grey[600]))
                  : Column(children: docs.map((d) => _DocTile(doc: d)).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocTile extends StatelessWidget {
  final VerificationDoc doc;
  const _DocTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final color = doc.status == 'APPROVED' ? Colors.green : doc.status == 'REJECTED' ? Colors.red : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          doc.status == 'APPROVED' ? Icons.verified : doc.status == 'REJECTED' ? Icons.cancel : Icons.pending,
          color: color,
        ),
        title: Text(doc.docType.replaceAll('_', ' ')),
        subtitle: doc.rejectionReason != null ? Text(doc.rejectionReason!, style: const TextStyle(color: Colors.red, fontSize: 12)) : null,
        trailing: Chip(
          label: Text(doc.status, style: const TextStyle(fontSize: 11)),
          backgroundColor: color.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: color),
          side: BorderSide.none,
        ),
      ),
    );
  }
}
