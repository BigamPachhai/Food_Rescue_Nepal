import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/constants/api_endpoints.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/settings/providers/settings_provider.dart';

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

const _androidChannel = AndroidNotificationChannel(
  'food_rescue_channel',
  'Food Rescue Notifications',
  description: 'Order updates, nearby food, pickup reminders',
  importance: Importance.high,
);

// Stream used to forward notification tap payloads into the widget tree.
final _notificationTapController =
    StreamController<Map<String, dynamic>>.broadcast();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Called from `flutter_local_notifications` when the user taps a foreground
/// notification.  Decodes the payload and pushes it onto the navigation stream.
@pragma('vm:entry-point')
void _onLocalNotificationTap(NotificationResponse response) {
  if (response.payload == null) return;
  try {
    final data = jsonDecode(response.payload!) as Map<String, dynamic>;
    _notificationTapController.add(data);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Show local notification when app is in foreground, carrying message data
    // as payload so tapping it triggers navigation.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background → foreground via notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _notificationTapController.add(message.data);
    });
  } catch (_) {
    // Firebase not configured — continue without push notifications.
  }

  runApp(const ProviderScope(child: FoodRescueApp()));
}

/// Called after login/register to register the device FCM token with the backend.
Future<void> registerFcmToken(Dio dio) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await dio.post(ApiEndpoints.registerFcmToken, data: {'fcmToken': token});
    }
  } catch (_) {}
}

class FoodRescueApp extends ConsumerStatefulWidget {
  const FoodRescueApp({super.key});

  @override
  ConsumerState<FoodRescueApp> createState() => _FoodRescueAppState();
}

class _FoodRescueAppState extends ConsumerState<FoodRescueApp> {
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();

    // Handle notification tap from terminated state (cold start).
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        // Wait until the first frame so the router is fully initialised.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromData(message.data);
        });
      }
    });

    // Handle notification taps forwarded from onMessageOpenedApp and local
    // notifications (foreground taps).
    _notifSub = _notificationTapController.stream.listen(_navigateFromData);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  /// Resolves a navigation path from FCM message data and pushes it.
  ///
  /// Uses the type field to determine whether this notification was sent to a
  /// vendor or a customer so the correct shell route is used.
  void _navigateFromData(Map<String, dynamic> data) {
    final orderId = data['orderId'] as String?;
    final listingId = data['listingId'] as String?;
    final type = (data['type'] as String?) ?? '';

    final router = ref.read(routerProvider);
    final authState = ref.read(authProvider);

    if (orderId != null) {
      // NEW_ORDER and ORDER_CANCELLED are sent to vendors; everything else to
      // customers.  Also fall back on the current user role if type is absent.
      final isVendorNotif =
          type == 'NEW_ORDER' || type == 'ORDER_CANCELLED';
      final isVendor =
          authState is AuthAuthenticated && authState.user.isVendor;

      if (isVendorNotif || isVendor) {
        router.push('/vendor/orders/$orderId');
      } else {
        router.push('/customer/orders/$orderId');
      }
    } else if (listingId != null) {
      router.push('/customer/listing/$listingId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'Food Rescue Nepal',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(overscroll: false),
      builder: (context, child) => Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }
}
