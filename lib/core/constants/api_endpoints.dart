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
  static const String listingAutocomplete = '/listings/search/autocomplete';
  static const String listingRecommendations = '/listings/recommendations/for-me';

  // Orders (customer)
  static const String orders = '/orders';
  static const String customerOrders = '/orders/my';
  static String orderById(String id) => '/orders/$id';
  static String orderAccept(String id) => '/orders/$id/accept';
  static String orderReady(String id) => '/orders/$id/ready';
  static String orderPickup(String id) => '/orders/$id/pickup';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderReject(String id) => '/orders/$id/reject';
  static String orderExpire(String id) => '/orders/$id/expire';
  static const String orderBulkAccept = '/orders/bulk-accept';
  static const String vendorOrders = '/orders/vendor';

  // Favorites
  static const String customerFavorites = '/favorites';
  static String toggleFavorite(String listingId) => '/favorites/$listingId';
  static const String vendorFavorites = '/favorites/vendors';
  static String toggleVendorFavorite(String vendorId) => '/favorites/vendors/$vendorId';

  // User profile
  static const String customerProfile = '/users/profile';
  static const String deleteAccount = '/users/account';
  static const String notificationPrefs = '/users/notification-prefs';

  // Vendor
  static const String vendorProfile = '/vendors/profile';
  static const String vendorStats = '/vendors/stats';
  static const String vendorListings = '/listings/vendor/mine';
  static const String createListing = '/listings';
  static String vendorListingById(String id) => '/listings/$id';
  static String vendorOrderById(String id) => '/orders/$id';
  static const String vendorToggleOpen = '/vendors/toggle-open';
  static const String vendorAnalyticsCsv = '/vendors/analytics/export-csv';
  static const String vendorCoverageMap = '/vendors/coverage-map';

  // Admin
  static const String adminStats = '/admin/stats';
  static const String adminInsights = '/admin/insights';
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
  static String adminFeatureListing(String id) => '/admin/listings/$id/feature';
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

  // Feature 1: Waitlist
  static String waitlistJoin(String listingId) => '/waitlist/$listingId';
  static String waitlistLeave(String listingId) => '/waitlist/$listingId';
  static const String myWaitlist = '/waitlist/my';
  static String waitlistStatus(String listingId) => '/waitlist/$listingId/status';

  // Feature 2: Promo Codes
  static const String validatePromo = '/promo-codes/validate';
  static const String promoCodes = '/promo-codes';
  static String promoCodeToggle(String id) => '/promo-codes/$id/toggle';
  static const String myPromoCodes = '/promo-codes/my';
  static String myPromoCodeToggle(String id) => '/promo-codes/my/$id/toggle';
  static String myPromoCodeDelete(String id) => '/promo-codes/my/$id';

  // Feature 3: Loyalty Points
  static const String loyalty = '/loyalty';
  static const String loyaltyRedeem = '/loyalty/redeem';

  // Feature 4: Referral
  static const String referralMyCode = '/referral/my-code';
  static const String referralStats = '/referral/stats';
  static const String referralApply = '/referral/apply';

  // Feature 5: In-app Chat
  static String chatMessages(String orderId) => '/chat/$orderId';
  static String sendMessage(String orderId) => '/chat/$orderId';
  static const String chatUnreadCount = '/chat/unread/count';

  // Feature 6: Listing Templates
  static const String listingTemplates = '/listing-templates';
  static String listingTemplateById(String id) => '/listing-templates/$id';

  // Feature 7: Flash Sales
  static const String flashSales = '/flash-sales';
  static const String myFlashSales = '/flash-sales/my';
  static String cancelFlashSale(String id) => '/flash-sales/$id';

  // Feature 8: Operating Hours
  static const String myOperatingHours = '/operating-hours/my';
  static String vendorOperatingHours(String vendorId) => '/operating-hours/vendor/$vendorId';

  // Feature 9: Donations
  static const String donationPartners = '/donations/partners';
  static const String donationStats = '/donations/stats';
  static const String donate = '/donations';
  static const String vendorDonate = '/donations/vendor';
  static const String myDonations = '/donations/my';

  // Feature 10: Disputes
  static const String disputes = '/disputes';
  static const String myDisputes = '/disputes/my';
  static String resolveDispute(String id) => '/disputes/$id/resolve';

  // Feature 11: Announcements
  static const String announcements = '/announcements';
  static const String allAnnouncements = '/announcements/all';
  static String deactivateAnnouncement(String id) => '/announcements/$id/deactivate';

  // Feature 12: Audit Log
  static const String auditLog = '/audit-log';

  // Feature 13: Vendor Verification
  static const String uploadVerificationDoc = '/verification';
  static const String myVerificationDocs = '/verification/my';
  static const String pendingVerificationDocs = '/verification/pending';
  static String reviewVerificationDoc(String id) => '/verification/$id/review';

  // Feature 15: Data Export + Account Deletion
  static const String requestDataExport = '/data/export';
  static const String myDataExports = '/data/export';
  static String dataExportStatus(String id) => '/data/export/$id';
  static const String permanentDeleteAccount = '/data/account';
}
