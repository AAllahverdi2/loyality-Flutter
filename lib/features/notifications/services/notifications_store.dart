import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';
import 'package:loyallig_flutter/features/notifications/services/notification_permission_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_hub_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

enum NotificationToggleOutcome {
  enabled,
  disabled,
  openedSystemSettings,
  settingsOpenFailed,
}

class NotificationsStore extends ChangeNotifier {
  NotificationsStore._internal() {
    _attachGlobalListeners();
  }

  static final NotificationsStore instance = NotificationsStore._internal();

  final NotificationsService _service = NotificationsService();
  final NotificationsHubService _hubService = NotificationsHubService.instance;
  final NotificationPermissionService _permissionService =
      NotificationPermissionService.instance;

  static const int _defaultPageSize = 20;

  final _liveToastController = StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get liveToastStream => _liveToastController.stream;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  int _currentPage = 1;
  bool _hasMore = false;
  bool _hasLoadedOnce = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  DateTime? _lastExplicitUnreadAt;
  Future<void>? _initFuture;
  Future<void>? _unreadFuture;

  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.notDetermined;
  bool _localNotificationsEnabled = true;
  bool _preferencesLoaded = false;
  bool _awaitingSettingsReturn = false;

  List<AppNotification> get notifications =>
      List<AppNotification>.unmodifiable(_notifications);

  int get unreadCount => _unreadCount;

  bool get hasUnread => _unreadCount > 0;

  bool get hasLoadedOnce => _hasLoadedOnce;

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get hasMore => _hasMore;

  String? get errorMessage => _errorMessage;

  NotificationPermissionStatus get permissionStatus => _permissionStatus;

  bool get localNotificationsEnabled => _localNotificationsEnabled;

  bool get isOsNotificationPermissionGranted =>
      !_permissionService.isPermissionSupported ||
      _permissionStatus == NotificationPermissionStatus.granted;

  bool get isOsNotificationPermissionDenied =>
      _permissionService.isPermissionSupported &&
      (_permissionStatus == NotificationPermissionStatus.denied ||
          _permissionStatus ==
              NotificationPermissionStatus.permanentlyDenied);

  bool get isNativeNotificationPlatform => _permissionService.isNativePlatform;

  bool get isNotificationsEnabled =>
      _localNotificationsEnabled && isOsNotificationPermissionGranted;

  void _attachGlobalListeners() {
    _hubService.onNotificationReceived.listen(_handleIncomingNotification);
    _hubService.onUnreadCountUpdated.listen(_handleUnreadCountUpdated);
    _hubService.onConnectionStateChanged.listen((state) {
      if (state == HubConnectionState.Connected) {
        unawaited(refreshUnreadCount());
        if (_hasLoadedOnce) {
          unawaited(loadInitial(silent: true));
        }
      }
    });
    NetworkMonitor.instance.reconnectNotifier.addListener(() {
      unawaited(syncSession(forceUnreadRefresh: true));
    });
  }

  Future<bool> _hasSession() async {
    final hasTokenInMemory =
        ApiClient.instance.accessToken != null &&
        ApiClient.instance.accessToken!.trim().isNotEmpty;
    return hasTokenInMemory || await TokenStorage.hasValidSession();
  }

  /// Tətbiq açıldıqda / giriş edildikdə qlobal bildiriş sessiyasını başladır.
  /// Əvvəlcə REST unread-count çağırılır ki, token köhnəlibsə 401 interceptor
  /// onu yeniləsin və SignalR Hub təzə JWT ilə qoşulsun.
  Future<void> initGlobalSession() {
    final ongoing = _initFuture;
    if (ongoing != null) return ongoing;

    final future = _runInitGlobalSession();
    _initFuture = future;
    return future.whenComplete(() {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
    });
  }

  Future<void> initPreferences() async {
    final localEnabled =
        await _permissionService.getLocalNotificationsEnabled();
    final status = await _permissionService.checkPermissionStatus();
    final changed =
        !_preferencesLoaded ||
        _localNotificationsEnabled != localEnabled ||
        _permissionStatus != status;
    _localNotificationsEnabled = localEnabled;
    _permissionStatus = status;
    _preferencesLoaded = true;
    if (changed) {
      notifyListeners();
    }
  }

  Future<void> refreshNotificationPermissionStatus() async {
    final status = await _permissionService.checkPermissionStatus();
    var changed = _permissionStatus != status;
    _permissionStatus = status;

    if (!_preferencesLoaded) {
      _localNotificationsEnabled =
          await _permissionService.getLocalNotificationsEnabled();
      _preferencesLoaded = true;
      changed = true;
    }

    if (_awaitingSettingsReturn) {
      _awaitingSettingsReturn = false;
      if (status == NotificationPermissionStatus.granted &&
          !_localNotificationsEnabled) {
        _localNotificationsEnabled = true;
        await _permissionService.setLocalNotificationsEnabled(true);
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }

  Future<bool> handleFirstLoginNotificationPermission() async {
    final result = await _permissionService
        .requestPermissionOnFirstLoginIfNeeded();
    if (!_preferencesLoaded) {
      _localNotificationsEnabled =
          await _permissionService.getLocalNotificationsEnabled();
      _preferencesLoaded = true;
    }
    if (_permissionStatus != result.status) {
      _permissionStatus = result.status;
      notifyListeners();
    }
    return result.needsFallbackSheet;
  }

  Future<NotificationToggleOutcome> toggleNotifications(bool enable) async {
    if (!enable) {
      _awaitingSettingsReturn = false;
      _localNotificationsEnabled = false;
      await _permissionService.setLocalNotificationsEnabled(false);
      notifyListeners();
      return NotificationToggleOutcome.disabled;
    }

    final current = await _permissionService.checkPermissionStatus();
    _permissionStatus = current;

    if (!_permissionService.isPermissionSupported ||
        current == NotificationPermissionStatus.granted) {
      _awaitingSettingsReturn = false;
      _localNotificationsEnabled = true;
      await _permissionService.setLocalNotificationsEnabled(true);
      notifyListeners();
      return NotificationToggleOutcome.enabled;
    }

    if (current == NotificationPermissionStatus.notDetermined) {
      final requested = await _permissionService.requestPermission();
      _permissionStatus = requested;

      if (requested == NotificationPermissionStatus.granted) {
        _localNotificationsEnabled = true;
        await _permissionService.setLocalNotificationsEnabled(true);
        notifyListeners();
        return NotificationToggleOutcome.enabled;
      }

      if (requested == NotificationPermissionStatus.denied ||
          !_permissionService.isNativePlatform) {
        notifyListeners();
        return NotificationToggleOutcome.disabled;
      }
    }

    if (!_permissionService.isNativePlatform) {
      notifyListeners();
      return NotificationToggleOutcome.settingsOpenFailed;
    }

    // İstifadəçi sistem səviyyəsində icazəni rədd edibsə, tətbiqin bildiriş
    // parametrləri səhifəsinə yönləndiririk.
    _awaitingSettingsReturn = true;
    final opened = await _permissionService.openNotificationSettings();
    if (!opened) {
      _awaitingSettingsReturn = false;
    }
    notifyListeners();
    return opened
        ? NotificationToggleOutcome.openedSystemSettings
        : NotificationToggleOutcome.settingsOpenFailed;
  }

  Future<void> _runInitGlobalSession() async {
    if (!_preferencesLoaded) {
      await initPreferences();
    }
    if (!await _hasSession()) return;
    await refreshUnreadCount();
    if (!_hubService.isConnected) {
      await _hubService.initAndConnect();
    }
  }

  Future<void> syncSession({bool forceUnreadRefresh = false}) async {
    if (!await _hasSession()) return;
    if (forceUnreadRefresh) {
      await refreshUnreadCount();
    }
    if (!_hubService.isConnected) {
      final connected = await _hubService.initAndConnect();
      if (connected && !forceUnreadRefresh) {
        unawaited(refreshUnreadCount());
      }
    } else if (!forceUnreadRefresh) {
      unawaited(refreshUnreadCount());
    }
  }

  Future<void> onAppResumed() async {
    await refreshNotificationPermissionStatus();
    await syncSession(forceUnreadRefresh: true);
    if (_hasLoadedOnce) {
      unawaited(loadInitial(silent: true));
    }
  }

  Future<void> refreshUnreadCount() {
    final ongoing = _unreadFuture;
    if (ongoing != null) return ongoing;

    final future = _runRefreshUnreadCount();
    _unreadFuture = future;
    return future.whenComplete(() {
      if (identical(_unreadFuture, future)) {
        _unreadFuture = null;
      }
    });
  }

  Future<void> _runRefreshUnreadCount() async {
    if (!await _hasSession()) return;
    try {
      final count = await _service.getUnreadCount();
      if (_unreadCount != count) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadInitial({bool silent = false}) async {
    if (_isLoading) return;
    if (!_hubService.isConnected) {
      unawaited(_hubService.initAndConnect());
    }
    _isLoading = true;
    if (!silent) {
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        _service.getNotifications(page: 1, pageSize: _defaultPageSize),
        _service.getUnreadCount().catchError((_) => _unreadCount),
      ]);

      final pageResult = results[0] as NotificationsPageResult;
      final fetchedUnread = results[1] as int;

      _notifications = pageResult.items;
      _currentPage = 1;
      _hasMore = pageResult.hasMore;
      _unreadCount = fetchedUnread;
      _hasLoadedOnce = true;
      _errorMessage = null;
    } catch (_) {
      if (_notifications.isEmpty) {
        _errorMessage = tr('notifications_load_error');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final pageResult = await _service.getNotifications(
        page: nextPage,
        pageSize: _defaultPageSize,
      );

      final existingIds = _notifications
          .map((n) => n.id.trim().toLowerCase())
          .toSet();
      final merged = List<AppNotification>.from(_notifications);
      for (final item in pageResult.items) {
        if (!existingIds.contains(item.id.trim().toLowerCase())) {
          merged.add(item);
        }
      }

      _notifications = merged;
      _currentPage = nextPage;
      _hasMore = pageResult.hasMore;
    } catch (_) {
      // Səssiz saxlanılır, istifadəçi yenidən aşağı sürüşdürə bilər
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<AppNotification?> openNotificationDetail(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) return null;

    final normId = trimmedId.toLowerCase();
    final idx = _notifications.indexWhere(
      (n) => n.id.trim().toLowerCase() == normId,
    );
    final previous = idx != -1 ? _notifications[idx] : null;
    final wasUnread = previous == null || !previous.isRead;

    if (idx != -1 && wasUnread) {
      final updatedList = List<AppNotification>.from(_notifications);
      updatedList[idx] = updatedList[idx].copyWith(isRead: true);
      _notifications = updatedList;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      bool markedRead = !wasUnread;
      if (wasUnread) {
        markedRead = await _service
            .markAsRead(trimmedId)
            .catchError((_) => false);
      }

      final detail = await _service
          .getNotificationById(trimmedId)
          .catchError((_) => null);

      final resolvedAsRead = markedRead || (detail?.isRead == true);
      if (detail != null) {
        final normalizedDetail =
            resolvedAsRead ? detail.copyWith(isRead: true) : detail;
        final refreshIdx = _notifications.indexWhere(
          (n) => n.id.trim().toLowerCase() == normId,
        );
        if (refreshIdx != -1) {
          final updatedList = List<AppNotification>.from(_notifications);
          updatedList[refreshIdx] = normalizedDetail;
          _notifications = updatedList;
        }
        notifyListeners();
        unawaited(refreshUnreadCount());
        return normalizedDetail;
      }

      if (wasUnread && !resolvedAsRead && previous != null) {
        final rollbackIdx = _notifications.indexWhere(
          (n) => n.id.trim().toLowerCase() == normId,
        );
        if (rollbackIdx != -1) {
          final updatedList = List<AppNotification>.from(_notifications);
          updatedList[rollbackIdx] = previous;
          _notifications = updatedList;
          _unreadCount++;
          notifyListeners();
        }
      }
    } catch (_) {}

    unawaited(refreshUnreadCount());
    final finalIdx = _notifications.indexWhere(
      (n) => n.id.trim().toLowerCase() == normId,
    );
    return finalIdx != -1 ? _notifications[finalIdx] : null;
  }

  Future<void> markAsRead(String id) async {
    final normId = id.trim().toLowerCase();
    final idx = _notifications.indexWhere(
      (n) => n.id.trim().toLowerCase() == normId,
    );
    if (idx != -1 && _notifications[idx].isRead) return;

    final previous = idx != -1 ? _notifications[idx] : null;
    if (idx != -1) {
      final updatedList = List<AppNotification>.from(_notifications);
      updatedList[idx] = updatedList[idx].copyWith(isRead: true);
      _notifications = updatedList;
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }

    try {
      final ok = await _service.markAsRead(id);
      if (!ok && previous != null) {
        final rollbackIdx = _notifications.indexWhere(
          (n) => n.id.trim().toLowerCase() == normId,
        );
        if (rollbackIdx != -1) {
          final updatedList = List<AppNotification>.from(_notifications);
          updatedList[rollbackIdx] = previous;
          _notifications = updatedList;
          _unreadCount++;
          notifyListeners();
        }
      }
    } catch (_) {
      unawaited(refreshUnreadCount());
    }
  }

  Future<bool> markAllAsRead() async {
    if (_notifications.isEmpty && _unreadCount == 0) return false;

    final prevList = List<AppNotification>.from(_notifications);
    final prevUnread = _unreadCount;

    _notifications = _notifications
        .map((n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      final ok = await _service.markAllAsRead();
      if (!ok) {
        _notifications = prevList;
        _unreadCount = prevUnread;
        notifyListeners();
      } else {
        unawaited(refreshUnreadCount());
      }
      return ok;
    } catch (_) {
      _notifications = prevList;
      _unreadCount = prevUnread;
      notifyListeners();
      return false;
    }
  }

  void _handleIncomingNotification(AppNotification notification) {
    final normId = notification.id.trim().toLowerCase();
    final existingIdx = normId.isEmpty
        ? -1
        : _notifications.indexWhere(
            (n) => n.id.trim().toLowerCase() == normId,
          );

    final updatedList = List<AppNotification>.from(_notifications);
    if (existingIdx != -1) {
      updatedList.removeAt(existingIdx);
    }
    updatedList.insert(0, notification);
    _notifications = updatedList;

    final hasRecentExplicitUnread =
        _lastExplicitUnreadAt != null &&
        DateTime.now().difference(_lastExplicitUnreadAt!) <
            const Duration(milliseconds: 500);
    if (!hasRecentExplicitUnread && !notification.isRead && existingIdx == -1) {
      _unreadCount++;
    }
    _lastExplicitUnreadAt = null;
    notifyListeners();

    if (isNotificationsEnabled) {
      _liveToastController.add(notification);
    }
  }

  void _handleUnreadCountUpdated(int count) {
    _lastExplicitUnreadAt = DateTime.now();
    final clamped = count < 0 ? 0 : count;
    if (_unreadCount != clamped) {
      _unreadCount = clamped;
      notifyListeners();
    }
  }

  void clear() {
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _hasMore = false;
    _hasLoadedOnce = false;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    _lastExplicitUnreadAt = null;
    _initFuture = null;
    _unreadFuture = null;
    _awaitingSettingsReturn = false;
    notifyListeners();
  }
}
