import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';
import 'package:signalr_netcore/signalr_client.dart';

class NotificationsHubService {
  NotificationsHubService._internal();

  static final NotificationsHubService instance =
      NotificationsHubService._internal();

  HubConnection? _hubConnection;
  Completer<bool>? _connectCompleter;
  final Map<String, DateTime> _recentNotificationIds = {};

  final _notificationController = StreamController<AppNotification>.broadcast();
  final _unreadCountController = StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  Stream<AppNotification> get onNotificationReceived =>
      _notificationController.stream;

  Stream<int> get onUnreadCountUpdated => _unreadCountController.stream;

  Stream<HubConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  HubConnectionState get state =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<bool> initAndConnect() async {
    if (isConnected) {
      return true;
    }

    if (_connectCompleter != null) {
      return _connectCompleter!.future;
    }

    final completer = Completer<bool>();
    _connectCompleter = completer;

    try {
      String? initialToken = ApiClient.instance.accessToken;
      initialToken ??= await TokenStorage.getAccessToken();
      if (initialToken != null && initialToken.startsWith('Bearer ')) {
        initialToken = initialToken.substring(7).trim();
      }
      if (initialToken == null || initialToken.trim().isEmpty) {
        completer.complete(false);
        return false;
      }

      _connectionStateController.add(HubConnectionState.Connecting);

      if (_hubConnection != null) {
        try {
          await _hubConnection?.stop();
        } catch (_) {}
        _hubConnection = null;
      }

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiEndpoints.notificationsHub,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                String? token = ApiClient.instance.accessToken;
                token ??= await TokenStorage.getAccessToken();
                if (token != null && token.startsWith('Bearer ')) {
                  token = token.substring(7).trim();
                }
                return token ?? '';
              },
            ),
          )
          .withAutomaticReconnect()
          .build();

      _setupListeners();

      _hubConnection?.onreconnecting(({error}) {
        _connectionStateController.add(HubConnectionState.Reconnecting);
      });

      _hubConnection?.onreconnected(({connectionId}) {
        _connectionStateController.add(HubConnectionState.Connected);
      });

      _hubConnection?.onclose(({error}) {
        _connectionStateController.add(HubConnectionState.Disconnected);
        if (error != null && kDebugMode) {
          debugPrint('⚠️ [NOTIF_HUB] Bağlantı kəsildi: $error');
        }
      });

      await _hubConnection?.start();
      _connectionStateController.add(HubConnectionState.Connected);
      if (!completer.isCompleted) {
        completer.complete(true);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [NOTIF_HUB] Qoşulma xətası: $e');
      }
      _connectionStateController.add(HubConnectionState.Disconnected);
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      _connectCompleter = null;
    }
  }

  Map<String, dynamic>? _extractNotificationMap(dynamic candidate) {
    Map<String, dynamic>? map;
    if (candidate is Map) {
      map = Map<String, dynamic>.from(candidate);
    } else if (candidate is String && candidate.trim().startsWith('{')) {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      }
    }
    if (map == null) return null;

    final lower = <String, dynamic>{
      for (final entry in map.entries)
        entry.key.toString().trim().toLowerCase(): entry.value,
    };
    for (final wrapperKey in const ['notification', 'data', 'result']) {
      final inner = lower[wrapperKey];
      if (inner is Map) {
        return Map<String, dynamic>.from(inner);
      }
    }
    return map;
  }

  int? _extractUnreadCount(dynamic candidate) {
    if (candidate is num) return candidate.toInt();
    if (candidate is Map) {
      final lower = <String, dynamic>{
        for (final entry in candidate.entries)
          entry.key.toString().trim().toLowerCase(): entry.value,
      };
      final unwrapped = lower['result'] ?? lower['data'] ?? candidate;
      if (unwrapped is num) return unwrapped.toInt();
      if (unwrapped is Map) {
        final innerLower = <String, dynamic>{
          for (final entry in unwrapped.entries)
            entry.key.toString().trim().toLowerCase(): entry.value,
        };
        final val =
            innerLower['unreadcount'] ??
            innerLower['unread_count'] ??
            innerLower['count'] ??
            innerLower['total'] ??
            innerLower['value'];
        if (val is num) return val.toInt();
        if (val != null) return int.tryParse(val.toString().trim());
      }
    }
    if (candidate is String) {
      final trimmed = candidate.trim();
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      if (trimmed.startsWith('{')) {
        final decoded = jsonDecode(trimmed);
        return _extractUnreadCount(decoded);
      }
    }
    return null;
  }

  void _setupListeners() {
    // 1. Yeni bildiriş: ReceiveNotification(notificationJson) və ya (userId, notificationJson)
    _hubConnection?.on('ReceiveNotification', (List<dynamic>? args) {
      try {
        if (args == null || args.isEmpty) return;

        Map<String, dynamic>? map;
        for (final arg in args) {
          map = _extractNotificationMap(arg);
          if (map != null) break;
        }

        if (map == null) return;
        final notification = AppNotification.fromJson(map);
        if (notification.id.isEmpty &&
            notification.title.isEmpty &&
            notification.body.isEmpty) {
          return;
        }
        if (notification.id.isNotEmpty) {
          final normId = notification.id.toLowerCase();
          final now = DateTime.now();
          _recentNotificationIds.removeWhere(
            (_, ts) => now.difference(ts) > const Duration(seconds: 6),
          );
          if (_recentNotificationIds.containsKey(normId)) {
            return;
          }
          _recentNotificationIds[normId] = now;
        }

        _notificationController.add(notification);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [NOTIF_HUB] ReceiveNotification parse xətası: $e');
        }
      }
    });

    // 2. Oxunmamış say yeniləndi: UnreadCountUpdated(count) və ya (userId, count)
    _hubConnection?.on('UnreadCountUpdated', (List<dynamic>? args) {
      try {
        if (args == null || args.isEmpty) return;
        int? parsedCount;
        for (final arg in args) {
          parsedCount = _extractUnreadCount(arg);
          if (parsedCount != null) break;
        }

        if (parsedCount != null) {
          _unreadCountController.add(parsedCount < 0 ? 0 : parsedCount);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [NOTIF_HUB] UnreadCountUpdated parse xətası: $e');
        }
      }
    });
  }

  Future<void> stop() async {
    try {
      await _hubConnection?.stop();
    } catch (_) {
    } finally {
      _hubConnection = null;
      _recentNotificationIds.clear();
      _connectionStateController.add(HubConnectionState.Disconnected);
    }
  }
}
