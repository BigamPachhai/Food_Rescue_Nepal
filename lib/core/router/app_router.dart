import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/customer/home/screens/customer_home_screen.dart';
import '../../features/customer/home/screens/listing_detail_screen.dart';
import '../../features/customer/map/screens/map_screen.dart';
import '../../features/customer/orders/screens/my_orders_screen.dart';
import '../../features/customer/orders/screens/order_detail_screen.dart';
import '../../features/customer/orders/screens/qr_display_screen.dart';
import '../../features/customer/favorites/screens/favorites_screen.dart';
import '../../features/customer/profile/screens/customer_profile_screen.dart';
import '../../features/customer/profile/screens/edit_profile_screen.dart';
import '../../features/vendor/dashboard/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/listings/screens/vendor_listings_screen.dart';
import '../../features/vendor/listings/screens/add_edit_listing_screen.dart';
import '../../features/vendor/orders/screens/vendor_orders_screen.dart';
import '../../features/vendor/orders/screens/vendor_order_detail_screen.dart';
import '../../features/vendor/orders/screens/qr_scanner_screen.dart';
import '../../features/vendor/profile/screens/vendor_profile_screen.dart';
import '../../features/vendor/profile/screens/edit_vendor_profile_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_user_detail_screen.dart';
import '../../features/admin/screens/admin_vendors_screen.dart';
import '../../features/admin/screens/admin_vendor_detail_screen.dart';
import '../../features/admin/screens/admin_listings_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_order_detail_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/reviews/screens/vendor_reviews_screen.dart';
import '../../features/reviews/providers/reviews_provider.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/how_it_works/screens/how_it_works_screen.dart';
import '../../features/customer/vendors/screens/customer_vendor_screen.dart';

// Shell widgets
class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    '/customer/home',
    '/customer/map',
    '/customer/orders',
    '/customer/profile',
  ];

  static const _profileSubPaths = [
    '/customer/favorites',
    '/customer/support',
    '/settings',
  ];

  int _tabIndex(String location) {
    if (_profileSubPaths.any((p) => location.startsWith(p))) return 3;
    final i = _tabs.indexWhere((t) => location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Reservations'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class VendorShell extends StatelessWidget {
  const VendorShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    '/vendor/dashboard',
    '/vendor/listings',
    '/vendor/orders',
    '/vendor/profile',
  ];

  static const _profileSubPaths = [
    '/vendor/reviews',
    '/vendor/settings',
  ];

  int _tabIndex(String location) {
    if (_profileSubPaths.any((p) => location.startsWith(p))) return 3;
    final i = _tabs.indexWhere((t) => location.startsWith(t));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabIndex(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Reservations'),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    '/admin/dashboard',
    '/admin/users',
    '/admin/vendors',
    '/admin/orders',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _tabs.indexWhere((t) => location.startsWith(t));
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index < 0 ? 0 : index,
        onTap: (i) => context.go(_tabs[i]),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Vendors'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
      ),
    );
  }
}

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoading = authState is AuthInitial || authState is AuthLoading;
      if (isLoading) return null;

      final onboardingState = ref.read(onboardingProvider);
      if (onboardingState.isLoading) return null;
      final onboardingDone = onboardingState.value ?? true;

      final isAuthenticated = authState is AuthAuthenticated;
      final loc = state.matchedLocation;
      final isLoginRoute = loc == '/login';
      final isRegisterRoute = loc.startsWith('/register');
      final isRootRoute = loc == '/';
      final isOnboardingRoute = loc == '/onboarding';
      final isPublicRoute = isLoginRoute ||
          isRegisterRoute ||
          isOnboardingRoute ||
          loc == '/forgot-password' ||
          loc == '/reset-password' ||
          loc == '/legal/privacy' ||
          loc == '/legal/terms' ||
          loc == '/how-it-works';

      // First-run: show onboarding before login
      if (!isAuthenticated && isRootRoute && !onboardingDone) {
        return '/onboarding';
      }
      // After onboarding completes, go to login
      if (!isAuthenticated && isOnboardingRoute && onboardingDone) {
        return '/login';
      }

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        final user = authState.user;

        // Redirect away from auth/root/onboarding routes
        if (isLoginRoute || isRegisterRoute || isRootRoute || isOnboardingRoute) {
          if (user.isCustomer) return '/customer/home';
          if (user.isVendor) return '/vendor/dashboard';
          if (user.isAdmin) return '/admin/dashboard';
        }

        // Block cross-role access
        if (user.isCustomer &&
            (loc.startsWith('/vendor/') || loc.startsWith('/admin/'))) {
          return '/customer/home';
        }
        if (user.isVendor &&
            (loc.startsWith('/customer/') || loc.startsWith('/admin/'))) {
          return '/vendor/dashboard';
        }
        if (user.isAdmin &&
            (loc.startsWith('/customer/') || loc.startsWith('/vendor/'))) {
          return '/admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/how-it-works', builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
        path: '/register/customer',
        builder: (_, __) => const RegisterScreen(role: 'CUSTOMER'),
      ),
      GoRoute(
        path: '/register/vendor',
        builder: (_, __) => const RegisterScreen(role: 'VENDOR'),
      ),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String?>? ?? {};
          return ResetPasswordScreen(email: extra['email'] ?? '');
        },
      ),
      // Shared routes accessible from any role (no shell/bottom nav)
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/legal/privacy', builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/legal/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/vendor/scanner', builder: (_, __) => const QrScannerScreen()),
      GoRoute(
        path: '/customer/qr/:id',
        builder: (_, state) => QrDisplayScreen(orderId: state.pathParameters['id']!),
      ),
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          GoRoute(path: '/customer/home', builder: (_, __) => const CustomerHomeScreen()),
          GoRoute(path: '/customer/map', builder: (_, __) => const MapScreen()),
          GoRoute(
            path: '/customer/listing/:id',
            builder: (_, state) => ListingDetailScreen(listingId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/customer/orders', builder: (_, __) => const MyOrdersScreen()),
          GoRoute(
            path: '/customer/orders/:id',
            builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/customer/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/customer/profile', builder: (_, __) => const CustomerProfileScreen()),
          GoRoute(path: '/customer/profile/edit', builder: (_, __) => const EditProfileScreen()),
          GoRoute(path: '/customer/support', builder: (_, __) => const SupportScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(
            path: '/customer/vendor/:id',
            builder: (_, state) =>
                CustomerVendorScreen(vendorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/customer/vendor/:id/reviews',
            builder: (_, state) =>
                VendorReviewsScreen(vendorId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/customer/orders/:id/review',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return WriteReviewScreen(
                orderId: state.pathParameters['id']!,
                vendorId: extra['vendorId'] as String? ?? '',
                vendorName: extra['vendorName'] as String? ?? 'Vendor',
                existingReview: extra['existingReview'] as ReviewEntity?,
              );
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => VendorShell(child: child),
        routes: [
          GoRoute(path: '/vendor/dashboard', builder: (_, __) => const VendorDashboardScreen()),
          GoRoute(path: '/vendor/listings', builder: (_, __) => const VendorListingsScreen()),
          GoRoute(
            path: '/vendor/listings/add',
            builder: (_, __) => const AddEditListingScreen(mode: ListingFormMode.add),
          ),
          GoRoute(
            path: '/vendor/listings/:id/edit',
            builder: (_, state) => AddEditListingScreen(
              mode: ListingFormMode.edit,
              listingId: state.pathParameters['id'],
            ),
          ),
          GoRoute(path: '/vendor/orders', builder: (_, __) => const VendorOrdersScreen()),
          GoRoute(
            path: '/vendor/orders/:id',
            builder: (_, state) => VendorOrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/vendor/profile', builder: (_, __) => const VendorProfileScreen()),
          GoRoute(path: '/vendor/profile/edit', builder: (_, __) => const EditVendorProfileScreen()),
          GoRoute(
            path: '/vendor/reviews/:vendorId',
            builder: (_, state) =>
                VendorReviewsScreen(vendorId: state.pathParameters['vendorId']!),
          ),
          GoRoute(path: '/vendor/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
          GoRoute(
            path: '/admin/users/:id',
            builder: (_, state) => AdminUserDetailScreen(userId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/admin/vendors', builder: (_, __) => const AdminVendorsScreen()),
          GoRoute(
            path: '/admin/vendors/:id',
            builder: (_, state) => AdminVendorDetailScreen(vendorId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/admin/listings', builder: (_, __) => const AdminListingsScreen()),
          GoRoute(path: '/admin/orders', builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(
            path: '/admin/orders/:id',
            builder: (_, state) => AdminOrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
