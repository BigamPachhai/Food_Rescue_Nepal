import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

final _searchHistoryProvider = StateNotifierProvider<_SearchHistoryNotifier, List<String>>(
  (ref) => _SearchHistoryNotifier(),
);

class _SearchHistoryNotifier extends StateNotifier<List<String>> {
  _SearchHistoryNotifier() : super([]) { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('search_history') ?? [];
  }

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    final updated = [query, ...state.where((s) => s != query)].take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', updated);
    state = updated;
  }

  Future<void> remove(String query) async {
    final updated = state.where((s) => s != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', updated);
    state = updated;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    state = [];
  }
}

class SearchHistoryScreen extends ConsumerWidget {
  final void Function(String)? onSelect;
  const SearchHistoryScreen({super.key, this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(_searchHistoryProvider);
    final trending = ['Dal Bhat', 'Bakery', 'Surprise Bag', 'Fresh Bread', 'Cafe Sweets', 'Grocery Rescue'];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Search History'),
        actions: [
          if (history.isNotEmpty)
            TextButton(onPressed: () => ref.read(_searchHistoryProvider.notifier).clear(), child: const Text('Clear All')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTextStyles.h5),
                const Icon(Icons.history_rounded, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            ...history.map((q) => _HistoryTile(
              query: q,
              onTap: () { onSelect?.call(q); Navigator.pop(context); },
              onDelete: () => ref.read(_searchHistoryProvider.notifier).remove(q),
            )),
            const Divider(height: 24),
          ],
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppColors.primaryMedium),
              const SizedBox(width: 8),
              Text('Trending Now', style: AppTextStyles.h5),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: trending.map((t) => ActionChip(
              label: Text(t),
              onPressed: () { onSelect?.call(t); if (Navigator.canPop(context)) Navigator.pop(context); },
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
              labelStyle: const TextStyle(color: AppColors.primaryDark),
            )).toList(),
          ),
          const SizedBox(height: 24),
          Text('Popular Categories', style: AppTextStyles.h5),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3,
            children: const [
              _CatCard(icon: '🎁', label: 'Surprise Bag'),
              _CatCard(icon: '🍞', label: 'Bakery'),
              _CatCard(icon: '🍽️', label: 'Restaurant'),
              _CatCard(icon: '☕', label: 'Cafe'),
              _CatCard(icon: '🛒', label: 'Grocery'),
              _CatCard(icon: '🍰', label: 'Sweets'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String query;
  final VoidCallback onTap, onDelete;
  const _HistoryTile({required this.query, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
    title: Text(query, style: AppTextStyles.bodyMedium),
    trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onDelete),
    onTap: onTap,
  );
}

class _CatCard extends StatelessWidget {
  final String icon, label;
  const _CatCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 24)),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
    ]),
  );
}
