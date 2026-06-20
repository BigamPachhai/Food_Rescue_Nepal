import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class FoodBankPartner {
  final String id, name;
  final String? description, logoUrl, address, contactEmail;
  const FoodBankPartner({required this.id, required this.name, this.description, this.logoUrl, this.address, this.contactEmail});
  factory FoodBankPartner.fromJson(Map<String, dynamic> j) => FoodBankPartner(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        logoUrl: j['logoUrl'] as String?,
        address: j['address'] as String?,
        contactEmail: j['contactEmail'] as String?,
      );
}

final donationPartnersProvider = FutureProvider<List<FoodBankPartner>>((ref) async {
  final dio = ref.read(dioClientProvider);
  final res = await dio.get(ApiEndpoints.donationPartners);
  final raw = res.data as Map<String, dynamic>;
  final data = raw['data'];
  final items = data is List ? data : <dynamic>[];
  return items.map((e) => FoodBankPartner.fromJson(e as Map<String, dynamic>)).toList();
});

class DonationsScreen extends ConsumerWidget {
  const DonationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(donationPartnersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Food Bank Donations')),
      body: partnersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (partners) => partners.isEmpty
            ? const Center(child: Text('No food bank partners yet'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: partners.length,
                itemBuilder: (ctx, i) => _PartnerCard(partner: partners[i]),
              ),
      ),
    );
  }
}

class _PartnerCard extends ConsumerWidget {
  final FoodBankPartner partner;
  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (partner.logoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(partner.logoUrl!, width: 48, height: 48, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.volunteer_activism, color: Colors.green[700]),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (partner.address != null) Text(partner.address!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ]),
                  ),
                ],
              ),
              if (partner.description != null) ...[
                const SizedBox(height: 8),
                Text(partner.description!, style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restaurant, size: 16),
                    label: const Text('Donate Food'),
                    onPressed: () => _showDonateSheet(context, ref, partner, isFood: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.monetization_on, size: 16),
                    label: const Text('Donate Money'),
                    onPressed: () => _showDonateSheet(context, ref, partner, isFood: false),
                  ),
                ),
              ]),
            ],
          ),
        ),
      );

  void _showDonateSheet(BuildContext context, WidgetRef ref, FoodBankPartner partner, {required bool isFood}) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donate to ${partner.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: isFood ? TextInputType.text : TextInputType.number,
              decoration: InputDecoration(
                labelText: isFood ? 'Describe the food you\'re donating' : 'Amount (NPR)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  try {
                    final dio = ref.read(dioClientProvider);
                    await dio.post(ApiEndpoints.donate, data: {
                      'partnerId': partner.id,
                      if (isFood) 'foodDescription': ctrl.text else 'amountNpr': int.tryParse(ctrl.text) ?? 0,
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Thank you for your donation! 🙏')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Confirm Donation'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
