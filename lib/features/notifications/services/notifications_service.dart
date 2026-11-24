import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';

class NotificationsService {
  final ApiClient _client = ApiClient.instance;

  static Map<String, dynamic> _lowerMap(Map raw) {
    return <String, dynamic>{
      for (final e in raw.entries) e.key.toString().trim().toLowerCase(): e.value,
    };
  }

  static dynamic _unwrapPayload(dynamic data) {
    if (data is Map) {
      final lower = _lowerMap(data);
      if (lower.containsKey('result') || lower.containsKey('data')) {
        return lower['result'] ?? lower['data'];
      }
    }
    return data;
  }

  /// GET /api/notifications?page=1&pageSize=20
  Future<NotificationsPageResult> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _client.get(
      ApiEndpoints.notificationsList,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    if (response.statusCode == 200 && response.data != null) {
      final payload = _unwrapPayload(response.data);

      List<dynamic> rawList = [];
      int? totalCount;
      bool? explicitHasNext;

      if (payload is List) {
        rawList = payload;
      } else if (payload is Map) {
        final lower = _lowerMap(payload);
        final candidates =
            lower['items'] ??
            lower['notifications'] ??
            lower['data'] ??
            lower['list'];
        if (candidates is List) {
          rawList = candidates;
        }
        final rawTotal = lower['totalcount'] ?? lower['total'];
        if (rawTotal is num) {
          totalCount = rawTotal.toInt();
        } else if (rawTotal != null) {
          totalCount = int.tryParse(rawTotal.toString());
        }
        if (lower['hasnextpage'] is bool) {
          explicitHasNext = lower['hasnextpage'] as bool;
        } else if (lower['hasmore'] is bool) {
          explicitHasNext = lower['hasmore'] as bool;
        }
      }

      final items = rawList
          .whereType<Map>()
          .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
          .where(
            (n) =>
                n.id.isNotEmpty || n.title.isNotEmpty || n.body.isNotEmpty,
          )
          .toList();

      final resolvedTotal = totalCount ?? items.length;
      final hasMore =
          explicitHasNext ??
          (totalCount != null
              ? (page * pageSize) < totalCount && items.isNotEmpty
              : items.length >= pageSize);

      return NotificationsPageResult(
        items: items,
        page: page,
        pageSize: pageSize,
        totalCount: resolvedTotal,
        hasMore: hasMore,
      );
    }

    return NotificationsPageResult(
      items: const [],
      page: page,
      pageSize: pageSize,
      totalCount: 0,
      hasMore: false,
    );
  }

  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    final response = await _client.get(ApiEndpoints.notificationsUnreadCount);
    if (response.statusCode == 200 && response.data != null) {
      final payload = _unwrapPayload(response.data);
      if (payload is num) return payload.toInt().clamp(0, 999999);
      if (payload is Map) {
        final lower = _lowerMap(payload);
        final rawCount =
            lower['unreadcount'] ??
            lower['unread_count'] ??
            lower['count'] ??
            lower['total'] ??
            lower['value'];
        if (rawCount is num) return rawCount.toInt().clamp(0, 999999);
        if (rawCount != null) {
          return (int.tryParse(rawCount.toString().trim()) ?? 0).clamp(
            0,
            999999,
          );
        }
      } else if (payload != null) {
        return (int.tryParse(payload.toString().trim()) ?? 0).clamp(0, 999999);
      }
    }
    return 0;
  }

  /// GET /api/Notifications/{id}
  Future<AppNotification?> getNotificationById(String id) async {
    final response = await _client.get(ApiEndpoints.notificationById(id));
    if (response.statusCode == 200 && response.data != null) {
      final payload = _unwrapPayload(response.data);
      if (payload is Map) {
        return AppNotification.fromJson(Map<String, dynamic>.from(payload));
      }
    }
    return null;
  }

  /// POST /api/Notifications/{id}/read
  Future<bool> markAsRead(String id) async {
    final response = await _client.post(
      ApiEndpoints.notificationMarkRead(id),
    );
    final code = response.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  /// POST /api/Notifications/read-all
  Future<bool> markAllAsRead() async {
    final response = await _client.post(
      ApiEndpoints.notificationsReadAll,
    );
    final code = response.statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  bool _isSuccessResponse(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) return false;
    final data = response.data;
    if (data is Map && data['isSuccess'] == false) {
      return false;
    }
    return true;
  }

  /// POST /api/Notifications/device-token
  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceId,
    required String platform,
  }) async {
    final response = await _client.post(
      ApiEndpoints.notificationsDeviceToken,
      data: {
        'fcmToken': fcmToken,
        'deviceId': deviceId,
        'platform': platform,
      },
    );
    final ok = _isSuccessResponse(response);
    if (kDebugMode) {
      debugPrint(
        '📲 [PUSH_API] POST device-token status=${response.statusCode} ok=$ok platform=$platform deviceId=$deviceId data=${response.data}',
      );
    }
    return ok;
  }

  /// DELETE /api/Notifications/device-token?deviceId={deviceId}
  Future<bool> unregisterDeviceToken({
    required String deviceId,
    String? fcmToken,
  }) async {
    final response = await _client.delete(
      ApiEndpoints.notificationsDeviceToken,
      queryParameters: {'deviceId': deviceId},
      data: {
        'deviceId': deviceId,
        if (fcmToken != null && fcmToken.trim().isNotEmpty)
          'fcmToken': fcmToken.trim(),
      },
    );
    final ok = _isSuccessResponse(response);
    if (kDebugMode) {
      debugPrint(
        '📲 [PUSH_API] DELETE device-token status=${response.statusCode} ok=$ok deviceId=$deviceId',
      );
    }
    return ok;
  }

  /// POST /api/Notifications/preferences
  Future<bool> updatePreferences({
    required String deviceId,
    required bool enabled,
  }) async {
    final response = await _client.post(
      ApiEndpoints.notificationsPreferences,
      data: {
        'deviceId': deviceId,
        'enabled': enabled,
      },
    );
    final ok = _isSuccessResponse(response);
    if (kDebugMode) {
      debugPrint(
        '📲 [PUSH_API] POST preferences status=${response.statusCode} ok=$ok enabled=$enabled deviceId=$deviceId data=${response.data}',
      );
    }
    return ok;
  }
}
