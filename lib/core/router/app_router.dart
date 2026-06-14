import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
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
import '../../features/notifications/screens/notifications_screen.dart';

// Shell widgets
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _currentIndex = 0;
  final _tabs = ['/customer/home', '/customer/map', '/customer/orders', '/customer/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class VendorShell extends StatefulWidget {
  const VendorShell({super.key, required this.child});
  final Widget child;
  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _currentIndex = 0;
  final _tabs = ['/vendor/dashboard', '/vendor/listings', '/vendor/orders', '/vendor/profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined), activeIcon: Icon(Icons.restaurant_menu), label: 'Listings'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: 'Profile'),
        ],
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  final _tabs = ['/admin/dashboard', '/admin/users', '/admin/vendors', '/admin/orders'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(_tabs[i]);
        },
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

      final isAuthenticated = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation.startsWith('/register');
      final isRootRoute = state.matchedLocation == '/';

      if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        final user = authState.user;
        if (isLoginRoute || isRegisterRoute || isRootRoute) {
          if (user.isCustomer) return '/customer/home';
          if (user.isVendor) return '/vendor/dashboard';
          if (user.isAdmin) return '/admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
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
          GoRoute(
            path: '/customer/orders/:id/qr',
            builder: (_, state) => QrDisplayScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/customer/favorites', builder: (_, __) => const FavoritesScreen()),
          GoRoute(path: '/customer/profile', builder: (_, __) => const CustomerProfileScreen()),
          GoRoute(path: '/customer/profile/edit', builder: (_, __) => const EditProfileScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
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
          GoRoute(path: '/vendor/scanner', builder: (_, __) => const QrScannerScreen()),
          GoRoute(path: '/vendor/profile', builder: (_, __) => const VendorProfileScreen()),
          GoRoute(path: '/vendor/profile/edit', builder: (_, __) => const EditVendorProfileScreen()),
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
        ],
      ),
    ],
  );
});
