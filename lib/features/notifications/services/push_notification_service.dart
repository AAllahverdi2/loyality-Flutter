import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/routes/smooth_page_route.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/features/chat/chat_screen.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_conversations_store.dart';
import 'package:loyallig_flutter/features/notifications/notifications_screen.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_hub_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/main.dart';

const String _androidChannelId = 'azera_notifications';
const String _androidChannelName = 'Azera Bildirişlər';
const String _androidChannelDesc = 'Bildirişlər və dəstək mesajları';

const AndroidNotificationDetails _defaultAndroidDetails =
    AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: _androidChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

Future<void> _ensureAndroidNotificationChannel(
  FlutterLocalNotificationsPlugin plugin,
) async {
  if (!Platform.isAndroid) return;
  final androidImpl = plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidImpl?.createNotificationChannel(
    const AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      if (kDebugMode) {
        debugPrint(
          '📩 [PUSH_BG] Mesaj gəldi: id=${message.messageId} notif=${message.notification != null} data=${message.data}',
        );
      }
      // Əgər backend data-only payload (notification bloku olmadan) göndəribsə,
      // Android-də bağlı/arxa plan halında da bildirişi lokal göstəririk.
      if (Platform.isAndroid && message.notification == null) {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool('notifications_user_enabled') ?? true;
        if (!enabled) return;

        final title = message.data['title']?.toString().trim() ?? '';
        final body = message.data['body']?.toString().trim() ?? '';
        if (title.isEmpty && body.isEmpty) return;

        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
        );
        await _ensureAndroidNotificationChannel(plugin);
        final idSource =
            message.messageId ??
            message.data['notificationId']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        await plugin.show(
          id: idSource.hashCode & 0x7fffffff,
          title: title.isNotEmpty ? title : 'Azera Loyallıq',
          body: body,
          notificationDetails: const NotificationDetails(
            android: _defaultAndroidDetails,
          ),
          payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
        );
      }
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ [PUSH_BG] Xəta: $e');
    }
  }
}

class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService instance =
      PushNotificationService._internal();

  static const String androidChannelId = _androidChannelId;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationsService _notificationsService = NotificationsService();

  bool _initialized = false;
  bool _firebaseReady = false;
  bool _localReady = false;
  String? _lastSyncedToken;
  bool? _lastSyncedPreference;
  Map<String, dynamic>? _pendingLaunchData;

  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (_initialized || !_isMobilePlatform) return;
    _initialized = true;

    await _initFirebaseMessaging();
    await _initLocalNotifications();
  }

  Future<void> _initFirebaseMessaging() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = Firebase.apps.isNotEmpty;
    } catch (e) {
      _firebaseReady = false;
      if (kDebugMode) {
        debugPrint('⚠️ [PUSH] Firebase initialize atlandı: $e');
      }
      return;
    }

    if (!_firebaseReady) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (Platform.isIOS) {
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
      } catch (_) {}
    }

    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final clean = token.trim();
      if (clean.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔄 [PUSH] FCM token (onTokenRefresh): $clean');
        }
        unawaited(_registerTokenIfLoggedIn(clean, force: true));
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(Map<String, dynamic>.from(message.data));
    });

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _pendingLaunchData = Map<String, dynamic>.from(initialMessage.data);
      }
    } catch (_) {}
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        ),
        onDidReceiveNotificationResponse: _onLocalNotificationResponse,
      );

      await _ensureAndroidNotificationChannel(_localNotifications);

      _localReady = true;

      if (_pendingLaunchData == null) {
        final launchDetails =
            await _localNotifications.getNotificationAppLaunchDetails();
        final payload = launchDetails?.notificationResponse?.payload;
        if (launchDetails?.didNotificationLaunchApp == true &&
            payload != null &&
            payload.trim().isNotEmpty) {
          final decoded = _tryDecodePayload(payload);
          if (decoded != null) {
            _pendingLaunchData = decoded;
          }
        }
      }
    } catch (e) {
      _localReady = false;
      if (kDebugMode) {
        debugPrint('⚠️ [PUSH] Local notifications init xətası: $e');
      }
    }
  }

  Future<bool> _hasActiveSession() async {
    final hasInMemory =
        ApiClient.instance.accessToken != null &&
        ApiClient.instance.accessToken!.trim().isNotEmpty;
    return hasInMemory || await TokenStorage.hasValidSession();
  }

  Future<void> syncSessionPushSettings({
    required bool enabled,
    bool force = false,
  }) async {
    if (!await _hasActiveSession()) return;

    await syncPreferences(enabled: enabled, force: force);

    if (_isMobilePlatform && _firebaseReady) {
      try {
        if (Platform.isIOS) {
          final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          if (apnsToken == null || apnsToken.trim().isEmpty) {
            return;
          }
        }
        // ignore: deprecated_member_use
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.trim().isNotEmpty) {
          final cleanToken = token.trim();
          if (kDebugMode) {
            debugPrint('🔑 [PUSH] FCM token: $cleanToken');
          }
          await _registerTokenIfLoggedIn(cleanToken, force: force);
        } else if (kDebugMode) {
          debugPrint('⚠️ [PUSH] FCM token boş qayıtdı');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [PUSH] FCM token oxunarkən xəta: $e');
        }
      }
    }
  }

  Future<void> syncPreferences({
    required bool enabled,
    bool force = false,
  }) async {
    if (!await _hasActiveSession()) return;
    if (!force && _lastSyncedPreference == enabled) return;

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final ok = await _notificationsService.updatePreferences(
        deviceId: deviceId,
        enabled: enabled,
      );
      if (ok) {
        _lastSyncedPreference = enabled;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [PUSH] Preference sinxronizasiya xətası: $e');
      }
    }
  }

  Future<void> _registerTokenIfLoggedIn(
    String fcmToken, {
    bool force = false,
  }) async {
    if (!_isMobilePlatform || !await _hasActiveSession()) return;
    if (!force && _lastSyncedToken == fcmToken) return;

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final ok = await _notificationsService.registerDeviceToken(
        fcmToken: fcmToken,
        deviceId: deviceId,
        platform: platform,
      );
      if (ok) {
        _lastSyncedToken = fcmToken;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [PUSH] Device token qeydiyyat xətası: $e');
      }
    }
  }

  /// Çıxış (logout) zamanı token hələ qüvvədəykən backend-dən cihaz tokenini silir.
  Future<void> unregisterDeviceToken() async {
    if (!await _hasActiveSession()) {
      resetSessionCache();
      return;
    }

    String? fcmToken = _lastSyncedToken;
    if (_isMobilePlatform && _firebaseReady && (fcmToken == null || fcmToken.isEmpty)) {
      try {
        if (!Platform.isIOS ||
            await FirebaseMessaging.instance.getAPNSToken() != null) {
          // ignore: deprecated_member_use
          fcmToken = await FirebaseMessaging.instance.getToken();
        }
      } catch (_) {}
    }

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      await _notificationsService.unregisterDeviceToken(
        deviceId: deviceId,
        fcmToken: fcmToken,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [PUSH] Token silinmə xətası: $e');
      }
    } finally {
      resetSessionCache();
    }
  }

  void resetSessionCache() {
    _lastSyncedToken = null;
    _lastSyncedPreference = null;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint(
        '📩 [PUSH_FG] Mesaj gəldi: id=${message.messageId} notif=${message.notification?.title}/${message.notification?.body} data=${message.data}',
      );
    }
    final data = Map<String, dynamic>.from(message.data);
    final action = data['action']?.toString().trim().toLowerCase();

    if (action == 'open_chat') {
      unawaited(
        SupportConversationsStore.instance.refreshConversations(silent: true),
      );
      if (!NotificationsStore.instance.isNotificationsEnabled) return;

      final convId = data['conversationId']?.toString().trim().toLowerCase();
      final activeConvId = SupportChatHubService.instance.activeConversationId
          ?.trim()
          .toLowerCase();
      if (convId != null && convId.isNotEmpty && convId == activeConvId) {
        return;
      }

      await _showLocalSystemNotification(message);
      return;
    }

    unawaited(NotificationsStore.instance.refreshUnreadCount());
    if (!NotificationsStore.instance.isNotificationsEnabled) return;

    // SignalR bağlıdırsa tətbiqdaxili canlı toast artıq göstərilir;
    // bağlı deyilsə sistem bildirişi kimi göstərib sayğacı/siyahını yeniləyirik.
    if (!NotificationsHubService.instance.isConnected) {
      await _showLocalSystemNotification(message);
    }
  }

  Future<void> _showLocalSystemNotification(RemoteMessage message) async {
    if (!_localReady || !_isMobilePlatform) return;

    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Azera Loyallıq';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';

    if (title.trim().isEmpty && body.trim().isEmpty) return;

    final idSource =
        message.messageId ??
        message.data['notificationId']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final id = idSource.hashCode & 0x7fffffff;

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: _defaultAndroidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  void _onLocalNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.trim().isEmpty) {
      _handleNotificationTap(const {});
      return;
    }
    final decoded = _tryDecodePayload(payload) ?? const <String, dynamic>{};
    _handleNotificationTap(decoded);
  }

  Map<String, dynamic>? _tryDecodePayload(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingLaunchData = data;
      return;
    }
    _navigateWithData(nav, data);
  }

  /// Tətbiq bağlı vəziyyətdən bildirişə basılaraq açıldıqda,
  /// Splash/PIN kilidi keçildikdən sonra MainScreen içindən çağırılır.
  void consumePendingNavigation(BuildContext context) {
    final data = _pendingLaunchData;
    if (data == null || !context.mounted) return;
    _pendingLaunchData = null;

    final nav = Navigator.of(context);
    _navigateWithData(nav, data);
  }

  void _navigateWithData(NavigatorState nav, Map<String, dynamic> data) {
    final action = data['action']?.toString().trim().toLowerCase();
    if (action == 'open_chat') {
      final convId = data['conversationId']?.toString().trim();
      if (convId != null && convId.isNotEmpty) {
        nav.push(
          SmoothPageRoute<void>(
            builder: (_) => ChatScreen(conversationId: convId),
          ),
        );
        return;
      }
    }

    final notificationId =
        (data['notificationId'] ?? data['id'])?.toString().trim();
    nav.push(
      SmoothPageRoute<void>(
        builder: (_) => NotificationsScreen(
          initialNotificationId:
              (notificationId != null && notificationId.isNotEmpty)
                  ? notificationId
                  : null,
        ),
      ),
    );
  }
}
