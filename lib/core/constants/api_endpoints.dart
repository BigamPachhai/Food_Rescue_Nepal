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
  static const String googleSignIn = '/auth/google';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Listings
  static const String listings = '/listings';
  static String listingById(String id) => '/listings/$id';
  static const String uploadImage = '/upload/image';

  // Orders (customer)
  static const String orders = '/orders';
  static const String customerOrders = '/orders/my';
  static String orderById(String id) => '/orders/$id';
  static String orderAccept(String id) => '/orders/$id/accept';
  static String orderPickup(String id) => '/orders/$id/pickup';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderReject(String id) => '/orders/$id/reject';
  static String orderExpire(String id) => '/orders/$id/expire';

  // Favorites
  static const String customerFavorites = '/favorites';
  static String toggleFavorite(String listingId) => '/favorites/$listingId';
  static const String vendorFavorites = '/favorites/vendors';
  static String toggleVendorFavorite(String vendorId) => '/favorites/vendors/$vendorId';

  // User profile
  static const String customerProfile = '/users/profile';
  static const String deleteAccount = '/users/account';

  // Vendor
  static const String vendorProfile = '/vendors/profile';
  static const String vendorStats = '/vendors/stats';
  static const String vendorListings = '/listings/vendor/mine';
  static const String createListing = '/listings';
  static String vendorListingById(String id) => '/listings/$id';
  static const String vendorOrders = '/orders/vendor';
  static String vendorOrderById(String id) => '/orders/$id';

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
  static String adminOrderById(String id) => '/admin/orders/$id';

  // Notifications
  static const String notifications = '/notifications';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';
  static String deleteNotification(String id) => '/notifications/$id';
  static const String deleteAllNotifications = '/notifications/all';
  static const String registerFcmToken = '/notifications/fcm-token';

  // Reviews
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my';
  static String reviewByOrder(String orderId) => '/reviews/order/$orderId';
  static String vendorReviews(String vendorId) => '/reviews/vendor/$vendorId';
  static String reviewById(String id) => '/reviews/$id';
  static String reviewRespond(String id) => '/reviews/$id/respond';

  // Reports / Support
  static const String reports = '/reports';

  // Vendors (public)
  static const String vendors = '/vendors';
  static String vendorPublicById(String id) => '/vendors/$id';
}
