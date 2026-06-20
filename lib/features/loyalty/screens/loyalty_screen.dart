import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loyalty_provider.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loyaltyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Points')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Error loading loyalty data')),
        data: (loyalty) => RefreshIndicator(
          onRefresh: () => ref.refresh(loyaltyProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Balance card
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text('Your Points Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '${loyalty.balance}',
                        style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                      ),
                      const Text('pts', style: TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(label: 'Earned', value: '${loyalty.totalEarned}', icon: Icons.trending_up),
                          _Stat(label: 'Spent', value: '${loyalty.totalSpent}', icon: Icons.shopping_bag),
                          _Stat(
                            label: 'Worth',
                            value: 'Rs.${loyalty.balance ~/ 2}',
                            icon: Icons.monetization_on,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // How to earn
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How to earn points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const _EarnTip(icon: Icons.shopping_cart, text: 'Earn 10 pts per Rs.100 spent on orders'),
                      const _EarnTip(icon: Icons.people, text: 'Earn 100 pts for each friend you refer'),
                      const _EarnTip(icon: Icons.star, text: 'Earn 50 pts as a welcome bonus when joining via referral'),
                      const SizedBox(height: 4),
                      Text('2 points = Rs.1 discount', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Transaction history
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      if (loyalty.transactions.isEmpty)
                        Center(
                          child: Text('No transactions yet', style: TextStyle(color: Colors.grey[600])),
                        )
                      else
                        ...loyalty.transactions.map((tx) => _TransactionTile(tx: tx)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      );
}

class _EarnTip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EarnTip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _TransactionTile extends StatelessWidget {
  final LoyaltyTransaction tx;
  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.points > 0;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: isEarn ? Colors.green[100] : Colors.red[100],
        radius: 18,
        child: Icon(
          isEarn ? Icons.add : Icons.remove,
          color: isEarn ? Colors.green[700] : Colors.red[700],
          size: 16,
        ),
      ),
      title: Text(tx.description, style: const TextStyle(fontSize: 13)),
      subtitle: Text(DateFormat('MMM d, y').format(tx.createdAt), style: const TextStyle(fontSize: 11)),
      trailing: Text(
        '${isEarn ? '+' : ''}${tx.points} pts',
        style: TextStyle(
          color: isEarn ? Colors.green[700] : Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
