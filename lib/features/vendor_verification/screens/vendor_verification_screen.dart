import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

const _docTypes = ['BUSINESS_REG', 'TAX', 'ID', 'OTHER'];
const _docTypeLabels = {
  'BUSINESS_REG': 'Business Registration',
  'TAX': 'Tax Certificate',
  'ID': 'Identity Proof',
  'OTHER': 'Other',
};

class VendorVerificationScreen extends ConsumerStatefulWidget {
  const VendorVerificationScreen({super.key});

  @override
  ConsumerState<VendorVerificationScreen> createState() => _VendorVerificationScreenState();
}

class _VendorVerificationScreenState extends ConsumerState<VendorVerificationScreen> {
  String? _selectedDocType;
  String? _pickedFileName;
  String? _uploadedUrl;
  bool _uploading = false;
  bool _submitting = false;

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _uploading = true;
      _pickedFileName = picked.name;
      _uploadedUrl = null;
    });

    try {
      final dio = ref.read(dioClientProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(picked.path, filename: picked.name),
      });
      final res = await dio.post(ApiEndpoints.uploadImage, data: formData);
      final url = (res.data as Map<String, dynamic>)['data']?['url'] as String?;
      setState(() => _uploadedUrl = url);
      if (mounted && url == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed: no URL returned')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      setState(() => _pickedFileName = null);
    }
    if (mounted) setState(() => _uploading = false);
  }

  Future<void> _submit() async {
    if (_selectedDocType == null || _uploadedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a document type and upload a file')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioClientProvider);
      await dio.post(ApiEndpoints.uploadVerificationDoc, data: {
        'docType': _selectedDocType,
        'docUrl': _uploadedUrl,
      });
      ref.invalidate(verificationDocsProvider);
      setState(() {
        _selectedDocType = null;
        _pickedFileName = null;
        _uploadedUrl = null;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document submitted for review')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    if (mounted) setState(() => _submitting = false);
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
              items: _docTypes.map((t) => DropdownMenuItem(value: t, child: Text(_docTypeLabels[t] ?? t))).toList(),
              onChanged: (v) => setState(() => _selectedDocType = v),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _uploading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _uploadedUrl != null ? Colors.green : Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                  color: _uploadedUrl != null ? Colors.green.shade50 : Colors.grey.shade50,
                ),
                child: Row(children: [
                  if (_uploading)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(
                      _uploadedUrl != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: _uploadedUrl != null ? Colors.green : Colors.grey.shade600,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploading
                          ? 'Uploading...'
                          : _uploadedUrl != null
                              ? _pickedFileName ?? 'File uploaded'
                              : 'Tap to pick an image or document photo',
                      style: TextStyle(
                        color: _uploadedUrl != null ? Colors.green.shade700 : Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (_uploadedUrl != null)
                    TextButton(
                      onPressed: _uploading ? null : _pickFile,
                      child: const Text('Change'),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supported: JPG, PNG, WebP (max 10MB)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _submitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload_file),
                label: const Text('Submit Document'),
                onPressed: (_submitting || _uploading || _uploadedUrl == null) ? null : _submit,
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
        title: Text(_docTypeLabels[doc.docType] ?? doc.docType.replaceAll('_', ' ')),
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
