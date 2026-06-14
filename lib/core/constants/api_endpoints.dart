class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String apiPrefix = '/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Listings
  static const String listings = '/listings';
  static String listingById(String id) => '/listings/$id';
  static const String uploadImage = '/upload/image';

  // Orders
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderPickup(String id) => '/orders/$id/pickup';
  static String orderCancel(String id) => '/orders/$id/cancel';

  // Vendor
  static const String vendorProfile = '/vendor/profile';
  static const String vendorStats = '/vendor/stats';
  static const String vendorListings = '/vendor/listings';
  static String vendorListingById(String id) => '/vendor/listings/$id';
  static const String vendorOrders = '/vendor/orders';
  static String vendorOrderById(String id) => '/vendor/orders/$id';

  // Customer
  static const String customerProfile = '/customer/profile';
  static const String customerOrders = '/customer/orders';
  static const String customerFavorites = '/customer/favorites';
  static String toggleFavorite(String listingId) => '/customer/favorites/$listingId';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static String adminUserById(String id) => '/admin/users/$id';
  static String adminBanUser(String id) => '/admin/users/$id/ban';
  static String adminUnbanUser(String id) => '/admin/users/$id/unban';
  static const String adminVendors = '/admin/vendors';
  static String adminVendorById(String id) => '/admin/vendors/$id';
  static String adminApproveVendor(String id) => '/admin/vendors/$id/approve';
  static String adminSuspendVendor(String id) => '/admin/vendors/$id/suspend';
  static String adminRejectVendor(String id) => '/admin/vendors/$id/reject';
  static const String adminListings = '/admin/listings';
  static String adminDeactivateListing(String id) => '/admin/listings/$id/deactivate';
  static const String adminOrders = '/admin/orders';

  // Notifications
  static const String notifications = '/notifications';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';

  // Vendors (public)
  static const String vendors = '/vendors';
  static String vendorPublicById(String id) => '/vendors/$id';
}
