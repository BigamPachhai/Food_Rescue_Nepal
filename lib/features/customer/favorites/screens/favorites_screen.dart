import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/shimmer_card.dart';
import '../../home/screens/customer_home_screen.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: favAsync.when(
        data: (favs) {
          if (favs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              subtitle:
                  'Tap the heart icon on any listing to save it here.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primaryMedium,
            onRefresh: () => ref.read(favoritesProvider.notifier).fetch(),
            child: ListView.builder(
              itemCount: favs.length,
              itemBuilder: (_, i) => ListingCard(
                listing: favs[i],
                onTap: () =>
                    context.push('/customer/listing/${favs[i].id}'),
              ),
            ),
          );
        },
        loading: () => ListView.builder(
          itemCount: 3,
          itemBuilder: (_, __) => const ShimmerListingCard(),
        ),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(favoritesProvider.notifier).fetch(),
        ),
      ),
    );
  }
}
