import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/features/notifications/services/web_notification_permission_stub.dart'
    if (dart.library.js_interop) 'package:loyallig_flutter/features/notifications/services/web_notification_permission_web.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NotificationPermissionStatus {
  granted,
  notDetermined,
  denied,
  permanentlyDenied,
  unsupported,
}

/// Sistem (Android/iOS) bildiriş icazəsini və istifadəçinin lokal bildiriş
/// seçimini idarə edir.
class NotificationPermissionService {
  NotificationPermissionService._internal();

  static final NotificationPermissionService instance =
      NotificationPermissionService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.example.loyallig_flutter/notification_permissions',
  );

  static const String _keyPermissionPrompted =
      'notification_permission_prompted';
  static const String _keyLocalNotificationsEnabled =
      'notifications_user_enabled';

  bool _hasNativeRuntimeDialog = true;

  bool get isNativePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isWebNotificationSupported =>
      kIsWeb && checkWebNotificationStatus() != 'unsupported';

  bool get isPermissionSupported =>
      isNativePlatform || isWebNotificationSupported;

  bool get hasNativeRuntimeDialog => _hasNativeRuntimeDialog;

  Future<bool> hasPromptedPermission() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyPermissionPrompted) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setPromptedPermission(bool prompted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPermissionPrompted, prompted);
    } catch (_) {}
  }

  Future<bool> getLocalNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyLocalNotificationsEnabled) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setLocalNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLocalNotificationsEnabled, enabled);
    } catch (_) {}
  }

  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    if (kIsWeb) {
      return _mapWebStatusString(checkWebNotificationStatus());
    }
    if (!isNativePlatform) {
      return NotificationPermissionStatus.unsupported;
    }

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>('checkStatus');
      return await _mapNativeResult(raw);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [NOTIF_PERM] checkStatus xətası: $e');
      }
      return NotificationPermissionStatus.unsupported;
    }
  }

  Future<NotificationPermissionStatus> requestPermission() async {
    if (kIsWeb) {
      final mapped = _mapWebStatusString(
        await requestWebNotificationPermission(),
      );
      if (mapped == NotificationPermissionStatus.granted ||
          mapped == NotificationPermissionStatus.permanentlyDenied) {
        await setPromptedPermission(true);
      }
      return mapped;
    }
    if (!isNativePlatform) {
      return NotificationPermissionStatus.unsupported;
    }

    await setPromptedPermission(true);

    try {
      final raw = await BiometricService.instance.runWithSuppressedLock(
        () => _channel.invokeMapMethod<String, dynamic>('requestPermission'),
      );
      return await _mapNativeResult(raw);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [NOTIF_PERM] requestPermission xətası: $e');
      }
      return await checkPermissionStatus();
    }
  }

  Future<bool> openNotificationSettings() async {
    if (!isNativePlatform) return false;
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openNotificationSettings',
      );
      return opened == true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [NOTIF_PERM] openNotificationSettings xətası: $e');
      }
      return false;
    }
  }

  /// İlk girişdə / ilk açılışda native icazə dialoqunu göstərir.
  /// Chrome Web brauzeri klik jesti olmadan dialoqu buraxmazsa və ya
  /// Android < 13-də sistem dialoqu yoxdursa fallback modal lazım olduğunu qaytarır.
  Future<({NotificationPermissionStatus status, bool needsFallbackSheet})>
  requestPermissionOnFirstLoginIfNeeded() async {
    if (!isPermissionSupported) {
      return (
        status: NotificationPermissionStatus.unsupported,
        needsFallbackSheet: false,
      );
    }

    final alreadyPrompted = await hasPromptedPermission();
    final current = await checkPermissionStatus();

    if (alreadyPrompted) {
      return (status: current, needsFallbackSheet: false);
    }

    // Android 12 və aşağıda runtime POST_NOTIFICATIONS dialoqu yoxdur;
    // istifadəçiyə təmiz bir dəfəlik seçim modalı göstəririk.
    if (!kIsWeb && Platform.isAndroid && !_hasNativeRuntimeDialog) {
      return (status: current, needsFallbackSheet: true);
    }

    if (current == NotificationPermissionStatus.granted) {
      await setPromptedPermission(true);
      return (status: current, needsFallbackSheet: false);
    }

    final requested = await requestPermission();
    final needsWebClickSheet =
        kIsWeb && requested == NotificationPermissionStatus.notDetermined;

    return (status: requested, needsFallbackSheet: needsWebClickSheet);
  }

  NotificationPermissionStatus _mapWebStatusString(String status) {
    return switch (status) {
      'granted' => NotificationPermissionStatus.granted,
      'permanentlyDenied' => NotificationPermissionStatus.permanentlyDenied,
      'notDetermined' => NotificationPermissionStatus.notDetermined,
      _ => NotificationPermissionStatus.unsupported,
    };
  }

  Future<NotificationPermissionStatus> _mapNativeResult(
    Map<String, dynamic>? raw,
  ) async {
    if (raw == null) return NotificationPermissionStatus.unsupported;

    final sdkInt = (raw['sdkInt'] as num?)?.toInt() ?? 0;
    if (!kIsWeb && Platform.isAndroid && sdkInt > 0) {
      _hasNativeRuntimeDialog = sdkInt >= 33;
    }

    final granted = raw['granted'] == true;
    if (granted) {
      return NotificationPermissionStatus.granted;
    }

    final explicitStatus = raw['status']?.toString();
    if (explicitStatus == 'notDetermined') {
      return NotificationPermissionStatus.notDetermined;
    }
    if (explicitStatus == 'permanentlyDenied') {
      return NotificationPermissionStatus.permanentlyDenied;
    }

    final permissionGranted = raw['permissionGranted'] == true;
    final shouldShowRationale = raw['shouldShowRationale'] == true;

    if (sdkInt >= 33 && !permissionGranted) {
      final hasPrompted = await hasPromptedPermission();
      if (!hasPrompted && !shouldShowRationale) {
        return NotificationPermissionStatus.notDetermined;
      }
      if (shouldShowRationale) {
        return NotificationPermissionStatus.denied;
      }
      return NotificationPermissionStatus.permanentlyDenied;
    }

    return NotificationPermissionStatus.permanentlyDenied;
  }
}
