import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/data/auth_models.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_select_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/customer/home/screens/customer_home_screen.dart';
import '../../features/customer/home/screens/listing_detail_screen.dart';
import '../../features/customer/home/screens/advanced_filter_screen.dart';
import '../../features/customer/home/screens/trending_screen.dart';
import '../../features/customer/home/screens/flash_sales_screen.dart';
import '../../features/customer/home/screens/new_vendors_screen.dart';
import '../../features/customer/home/screens/dietary_alerts_screen.dart';
import '../../features/customer/map/screens/map_screen.dart';
import '../../features/customer/orders/screens/my_orders_screen.dart';
import '../../features/customer/orders/screens/order_detail_screen.dart';
import '../../features/customer/orders/screens/order_receipt_screen.dart';
import '../../features/customer/orders/screens/order_stats_screen.dart';
import '../../features/customer/orders/screens/pickup_calendar_screen.dart';
import '../../features/customer/orders/screens/qr_display_screen.dart';
import '../../features/customer/favorites/screens/favorites_screen.dart';
import '../../features/customer/profile/screens/customer_profile_screen.dart';
import '../../features/customer/profile/screens/edit_profile_screen.dart';
import '../../features/customer/profile/screens/referral_screen.dart';
import '../../features/customer/impact/screens/impact_tracker_screen.dart';
import '../../features/customer/achievements/screens/achievements_screen.dart';
import '../../features/customer/leaderboard/screens/leaderboard_screen.dart';
import '../../features/customer/rewards/screens/rewards_screen.dart';
import '../../features/customer/community/screens/community_screen.dart';
import '../../features/customer/community/screens/challenges_screen.dart';
import '../../features/customer/search/screens/search_history_screen.dart';
import '../../features/vendor/dashboard/screens/vendor_dashboard_screen.dart';
import '../../features/vendor/listings/screens/vendor_listings_screen.dart';
import '../../features/vendor/listings/screens/add_edit_listing_screen.dart';
import '../../features/vendor/listings/screens/vendor_listing_detail_screen.dart';
import '../../features/vendor/orders/screens/vendor_orders_screen.dart';
import '../../features/vendor/orders/screens/vendor_order_detail_screen.dart';
import '../../features/vendor/orders/screens/qr_scanner_screen.dart';
import '../../features/vendor/profile/screens/vendor_profile_screen.dart';
import '../../features/vendor/profile/screens/edit_vendor_profile_screen.dart';
import '../../features/vendor/analytics/screens/vendor_analytics_screen.dart';
import '../../features/vendor/analytics/screens/peak_hours_screen.dart';
import '../../features/vendor/analytics/screens/waste_report_screen.dart';
import '../../features/vendor/analytics/screens/revenue_report_screen.dart';
import '../../features/vendor/customers/screens/customer_insights_screen.dart';
import '../../features/vendor/inventory/screens/inventory_screen.dart';
import '../../features/vendor/promotions/screens/promotions_screen.dart';
import '../../features/vendor/hours/screens/operating_hours_screen.dart';
import '../../features/vendor/gallery/screens/vendor_gallery_screen.dart';
import '../../features/vendor/faq/screens/vendor_faq_screen.dart';
import '../../features/vendor/loyalty/screens/vendor_loyalty_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_user_detail_screen.dart';
import '../../features/admin/screens/admin_vendors_screen.dart';
import '../../features/admin/screens/admin_vendor_detail_screen.dart';
import '../../features/admin/screens/admin_listings_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_order_detail_screen.dart';
import '../../features/admin/screens/admin_analytics_screen.dart';
import '../../features/admin/screens/admin_moderation_screen.dart';
import '../../features/admin/screens/admin_announcements_screen.dart';
import '../../features/admin/screens/admin_audit_log_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/reviews/screens/write_review_screen.dart';
import '../../features/reviews/screens/vendor_reviews_screen.dart';
import '../../features/reviews/providers/reviews_provider.dart';
import '../../features/support/screens/support_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/accessibility_screen.dart';
import '../../features/settings/screens/notification_settings_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/legal/screens/privacy_policy_screen.dart';
import '../../features/legal/screens/terms_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import '../../features/how_it_works/screens/how_it_works_screen.dart';
import '../../features/customer/vendors/screens/customer_vendor_screen.dart';
// New feature screens
import '../../features/waitlist/screens/waitlist_screen.dart';
import '../../features/loyalty/screens/loyalty_screen.dart';
import '../../features/flash_sales/screens/flash_sales_screen.dart'
    as flash_new;
import '../../features/chat/screens/chat_screen.dart';
import '../../features/disputes/screens/dispute_screen.dart';
import '../../features/donations/screens/donations_screen.dart';
import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/referral/screens/referral_screen.dart' as referral_new;
import '../../features/customer/analytics/screens/spending_analytics_screen.dart';
import '../../features/vendor/operating_hours/screens/operating_hours_screen.dart'
    as oh_new;
import '../../features/vendor_verification/screens/vendor_verification_screen.dart';
import '../../features/gdpr/screens/gdpr_screen.dart';
import '../../features/settings/screens/notification_preferences_screen.dart';
import '../../features/settings/screens/language_screen.dart';
import '../../features/settings/screens/dark_mode_screen.dart';
import '../../features/settings/screens/app_lock_screen.dart';
import '../../features/admin/screens/admin_insights_screen.dart';

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
    '/customer/impact',
    '/customer/achievements',
    '/customer/leaderboard',
    '/customer/rewards',
    '/customer/community',
    '/customer/challenges',
    '/customer/search-history',
    '/customer/referral',
    '/customer/loyalty',
    '/customer/waitlist',
    '/customer/donations',
    '/customer/announcements',
    '/customer/referral-earn',
    '/customer/spending-analytics',
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Reservations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
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
    '/vendor/analytics',
    '/vendor/inventory',
    '/vendor/promotions',
    '/vendor/hours',
    '/vendor/gallery',
    '/vendor/faq',
    '/vendor/loyalty',
    '/vendor/customers',
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Listings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Reservations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Profile'),
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
    '/admin/listings',
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users'),
          BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Vendors'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: 'Listings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders'),
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

      if (!isAuthenticated && isRootRoute && !onboardingDone) {
        return '/onboarding';
      }
      if (!isAuthenticated && isOnboardingRoute && onboardingDone) {
        return '/login';
      }

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        final user = authState.user;

        if (isLoginRoute ||
            isRegisterRoute ||
            isRootRoute ||
            isOnboardingRoute) {
          if (user.isCustomer) return '/customer/home';
          if (user.isVendor) return '/vendor/dashboard';
          if (user.isAdmin) return '/admin/dashboard';
        }

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
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(
          path: '/how-it-works', builder: (_, __) => const HowItWorksScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RoleSelectScreen()),
      GoRoute(
          path: '/register/customer',
          builder: (_, __) => const RegisterScreen(role: 'CUSTOMER')),
      GoRoute(
        path: '/register/vendor',
        builder: (_, state) => RegisterScreen(
          role: 'VENDOR',
          googleUserData: state.extra as GoogleUserData?,
        ),
      ),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) {
          final extra = state.extra as Map<String, String?>? ?? {};
          return ResetPasswordScreen(email: extra['email'] ?? '');
        },
      ),
      // Shared routes
      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/legal/privacy',
          builder: (_, __) => const PrivacyPolicyScreen()),
      GoRoute(path: '/legal/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(
          path: '/vendor/scanner', builder: (_, __) => const QrScannerScreen()),
      // Settings (accessible from any role)
      GoRoute(
          path: '/settings/accessibility',
          builder: (_, __) => const AccessibilityScreen()),
      GoRoute(
          path: '/settings/notifications',
          builder: (_, __) => const NotificationSettingsScreen()),
      GoRoute(path: '/settings/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
          path: '/settings/language',
          builder: (_, __) => const LanguageScreen()),
      GoRoute(
          path: '/settings/dark-mode',
          builder: (_, __) => const DarkModeScreen()),
      GoRoute(
          path: '/settings/app-lock',
          builder: (_, __) => const AppLockScreen()),
      GoRoute(
          path: '/settings/privacy-data',
          builder: (_, __) => const GdprScreen()),
      GoRoute(
          path: '/settings/notification-prefs',
          builder: (_, __) => const NotificationPreferencesScreen()),
      // ── Customer Shell ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => CustomerShell(child: child),
        routes: [
          // Core
          GoRoute(
              path: '/customer/home',
              builder: (_, __) => const CustomerHomeScreen()),
          GoRoute(path: '/customer/map', builder: (_, __) => const MapScreen()),
          // Orders
          GoRoute(
              path: '/customer/orders',
              builder: (_, __) => const MyOrdersScreen()),
          GoRoute(
              path: '/customer/orders/stats',
              builder: (_, __) => const OrderStatsScreen()),
          GoRoute(
              path: '/customer/orders/calendar',
              builder: (_, __) => const PickupCalendarScreen()),
          GoRoute(
              path: '/customer/orders/:id',
              builder: (_, state) =>
                  OrderDetailScreen(orderId: state.pathParameters['id']!)),
          GoRoute(
              path: '/customer/orders/:id/receipt',
              builder: (_, state) =>
                  OrderReceiptScreen(orderId: state.pathParameters['id']!)),
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
          // Profile & social
          GoRoute(
              path: '/customer/profile',
              builder: (_, __) => const CustomerProfileScreen()),
          GoRoute(
              path: '/customer/profile/edit',
              builder: (_, __) => const EditProfileScreen()),
          GoRoute(
              path: '/customer/referral',
              builder: (_, __) => const ReferralScreen()),
          // Impact & gamification
          GoRoute(
              path: '/customer/impact',
              builder: (_, __) => const ImpactTrackerScreen()),
          GoRoute(
              path: '/customer/achievements',
              builder: (_, __) => const AchievementsScreen()),
          GoRoute(
              path: '/customer/leaderboard',
              builder: (_, __) => const LeaderboardScreen()),
          GoRoute(
              path: '/customer/rewards',
              builder: (_, __) => const RewardsScreen()),
          // Community
          GoRoute(
              path: '/customer/community',
              builder: (_, __) => const CommunityScreen()),
          GoRoute(
              path: '/customer/challenges',
              builder: (_, __) => const ChallengesScreen()),
          // Discovery
          GoRoute(
              path: '/customer/search-history',
              builder: (_, __) => const SearchHistoryScreen()),
          GoRoute(
              path: '/customer/trending',
              builder: (_, __) => const TrendingScreen()),
          GoRoute(
              path: '/customer/flash-sales',
              builder: (_, __) => const FlashSalesScreen()),
          GoRoute(
              path: '/customer/new-vendors',
              builder: (_, __) => const NewVendorsScreen()),
          GoRoute(
              path: '/customer/dietary-alerts',
              builder: (_, __) => const DietaryAlertsScreen()),
          GoRoute(
              path: '/customer/advanced-filter',
              builder: (_, __) =>
                  const AdvancedFilterScreen(initial: FilterOptions())),
          // Misc
          GoRoute(
              path: '/customer/support',
              builder: (_, __) => const SupportScreen()),
          // New features
          GoRoute(
              path: '/customer/loyalty',
              builder: (_, __) => const LoyaltyScreen()),
          GoRoute(
              path: '/customer/waitlist',
              builder: (_, __) => const WaitlistScreen()),
          GoRoute(
              path: '/customer/flash-deals',
              builder: (_, __) => const flash_new.FlashSalesScreen()),
          GoRoute(
              path: '/customer/donations',
              builder: (_, __) => const DonationsScreen()),
          GoRoute(
              path: '/customer/announcements',
              builder: (_, __) => const AnnouncementsScreen()),
          GoRoute(
              path: '/customer/referral-earn',
              builder: (_, __) => const referral_new.ReferralScreen()),
          GoRoute(
              path: '/customer/spending-analytics',
              builder: (_, __) => const SpendingAnalyticsScreen()),
          GoRoute(
              path: '/customer/qr/:id',
              builder: (_, state) =>
                  QrDisplayScreen(orderId: state.pathParameters['id']!)),
          GoRoute(
            path: '/customer/orders/:id/dispute',
            builder: (_, state) =>
                DisputeScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/customer/orders/:id/chat',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ChatScreen(
                orderId: state.pathParameters['id']!,
                currentUserId: extra['currentUserId'] as String? ?? '',
                otherPartyName: extra['otherPartyName'] as String? ?? 'Vendor',
              );
            },
          ),
        ],
      ),

      // ── Customer routes outside shell so back button works correctly ─────────
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
          path: '/customer/favorites',
          builder: (_, __) => const FavoritesScreen()),
      GoRoute(
          path: '/customer/listing/:id',
          builder: (_, state) =>
              ListingDetailScreen(listingId: state.pathParameters['id']!)),
      GoRoute(
          path: '/customer/vendor/:id',
          builder: (_, state) =>
              CustomerVendorScreen(vendorId: state.pathParameters['id']!)),
      GoRoute(
          path: '/customer/vendor/:id/reviews',
          builder: (_, state) =>
              VendorReviewsScreen(vendorId: state.pathParameters['id']!)),

      // ── Vendor Shell ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => VendorShell(child: child),
        routes: [
          // Core
          GoRoute(
              path: '/vendor/dashboard',
              builder: (_, __) => const VendorDashboardScreen()),
          GoRoute(
              path: '/vendor/listings',
              builder: (_, __) => const VendorListingsScreen()),
          GoRoute(
              path: '/vendor/listings/add',
              builder: (_, __) =>
                  const AddEditListingScreen(mode: ListingFormMode.add)),
          GoRoute(
              path: '/vendor/listings/:id',
              builder: (_, state) => VendorListingDetailScreen(
                  listingId: state.pathParameters['id']!)),
          GoRoute(
              path: '/vendor/listings/:id/edit',
              builder: (_, state) => AddEditListingScreen(
                  mode: ListingFormMode.edit,
                  listingId: state.pathParameters['id'])),
          GoRoute(
              path: '/vendor/orders',
              builder: (_, __) => const VendorOrdersScreen()),
          GoRoute(
              path: '/vendor/orders/:id',
              builder: (_, state) => VendorOrderDetailScreen(
                  orderId: state.pathParameters['id']!)),
          GoRoute(
              path: '/vendor/profile',
              builder: (_, __) => const VendorProfileScreen()),
          GoRoute(
              path: '/vendor/profile/edit',
              builder: (_, __) => const EditVendorProfileScreen()),
          // Analytics
          GoRoute(
              path: '/vendor/analytics',
              builder: (_, __) => const VendorAnalyticsScreen()),
          GoRoute(
              path: '/vendor/analytics/peak-hours',
              builder: (_, __) => const PeakHoursScreen()),
          GoRoute(
              path: '/vendor/analytics/revenue-report',
              builder: (_, __) => const RevenueReportScreen()),
          GoRoute(
              path: '/vendor/analytics/waste-report',
              builder: (_, __) => const WasteReportScreen()),
          // Store management
          GoRoute(
              path: '/vendor/customers',
              builder: (_, __) => const CustomerInsightsScreen()),
          GoRoute(
              path: '/vendor/inventory',
              builder: (_, __) => const InventoryScreen()),
          GoRoute(
              path: '/vendor/promotions',
              builder: (_, __) => const PromotionsScreen()),
          GoRoute(
              path: '/vendor/hours',
              builder: (_, __) => const OperatingHoursScreen()),
          GoRoute(
              path: '/vendor/gallery',
              builder: (_, __) => const VendorGalleryScreen()),
          GoRoute(
              path: '/vendor/faq', builder: (_, __) => const VendorFaqScreen()),
          GoRoute(
              path: '/vendor/loyalty',
              builder: (_, __) => const VendorLoyaltyScreen()),
          // Reviews & misc
          GoRoute(
              path: '/vendor/reviews/:vendorId',
              builder: (_, state) => VendorReviewsScreen(
                  vendorId: state.pathParameters['vendorId']!,
                  canRespond: true)),
          GoRoute(
              path: '/vendor/settings',
              builder: (_, __) => const SettingsScreen()),
          GoRoute(
              path: '/vendor/support',
              builder: (_, __) => const SupportScreen()),
          // New features
          GoRoute(
              path: '/vendor/verification',
              builder: (_, __) => const VendorVerificationScreen()),
          GoRoute(
              path: '/vendor/hours-new',
              builder: (_, __) => const oh_new.OperatingHoursScreen()),
          GoRoute(
            path: '/vendor/orders/:id/chat',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ChatScreen(
                orderId: state.pathParameters['id']!,
                currentUserId: extra['currentUserId'] as String? ?? '',
                otherPartyName:
                    extra['otherPartyName'] as String? ?? 'Customer',
              );
            },
          ),
        ],
      ),

      // ── Admin Shell ─────────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin/dashboard',
              builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUsersScreen()),
          GoRoute(
              path: '/admin/users/:id',
              builder: (_, state) =>
                  AdminUserDetailScreen(userId: state.pathParameters['id']!)),
          GoRoute(
              path: '/admin/vendors',
              builder: (_, __) => const AdminVendorsScreen()),
          GoRoute(
              path: '/admin/vendors/:id',
              builder: (_, state) => AdminVendorDetailScreen(
                  vendorId: state.pathParameters['id']!)),
          GoRoute(
              path: '/admin/listings',
              builder: (_, __) => const AdminListingsScreen()),
          GoRoute(
              path: '/admin/orders',
              builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(
              path: '/admin/orders/:id',
              builder: (_, state) =>
                  AdminOrderDetailScreen(orderId: state.pathParameters['id']!)),
          GoRoute(
              path: '/admin/analytics',
              builder: (_, __) => const AdminAnalyticsScreen()),
          GoRoute(
              path: '/admin/moderation',
              builder: (_, __) => const AdminModerationScreen()),
          GoRoute(
              path: '/admin/announcements',
              builder: (_, __) => const AdminAnnouncementsScreen()),
          GoRoute(
              path: '/admin/audit-log',
              builder: (_, __) => const AdminAuditLogScreen()),
          GoRoute(
              path: '/admin/insights',
              builder: (_, __) => const AdminInsightsScreen()),
        ],
      ),
    ],
  );
});
