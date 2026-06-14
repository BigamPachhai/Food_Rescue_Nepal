import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/shimmer_card.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _search = '';
  String _roleFilter = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_search));

    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.primarySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['', 'CUSTOMER', 'VENDOR', 'ADMIN'].map((role) {
                final label =
                    role.isEmpty ? 'All' : role[0] + role.substring(1).toLowerCase();
                final selected = _roleFilter == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _roleFilter = role),
                    selectedColor: AppColors.primaryMedium,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                    showCheckmark: false,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryMedium
                          : AppColors.primarySurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = _roleFilter.isEmpty
                    ? users
                    : users.where((u) => u.role == _roleFilter).toList();
                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.people_outline,
                    title: 'No users found',
                    subtitle: 'Try adjusting your search or filters.',
                  );
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _UserTile(user: filtered[i]),
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (_, __) => const ShimmerCard(height: 70),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(adminUsersProvider(_search)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySurface,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: const TextStyle(
              color: AppColors.primaryMedium, fontWeight: FontWeight.w700),
        ),
      ),
      title: Text(user.name, style: AppTextStyles.h6),
      subtitle: Text('${user.email} · ${user.role}',
          style: AppTextStyles.caption),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: user.isActive
                  ? AppColors.success
                  : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            Formatters.formatDate(user.createdAt),
            style: AppTextStyles.caption,
          ),
        ],
      ),
      onTap: () => context.push('/admin/users/${user.id}'),
    );
  }
}
