import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';

/// Tətbiq üzrə şəbəkə və server əlçatanlıq vəziyyətini idarə edən qlobal monitor.
class NetworkMonitor {
  NetworkMonitor._internal();
  static final NetworkMonitor instance = NetworkMonitor._internal();

  /// İnternet/server əlaqəsi kəsildikdə true olur
  final ValueNotifier<bool> isOfflineNotifier = ValueNotifier<bool>(false);

  /// Əlaqə bərpa olunduqda artırılır ki, açıq ekranlar məlumatı yeniləsin
  final ValueNotifier<int> reconnectNotifier = ValueNotifier<int>(0);

  Future<bool>? _activeCheck;

  bool get isOffline => isOfflineNotifier.value;

  /// Verilən xətanın şəbəkə/bağlantı xətası olub-olmadığını yoxlayır
  static bool isNetworkError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return true;
      }
      if (error.type == DioExceptionType.unknown && error.response == null) {
        return true;
      }
      return false;
    }

    final msg = error.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('connection aborted') ||
        msg.contains('connection errored') ||
        msg.contains('xmlhttprequest error') ||
        msg.contains('err_name_not_resolved') ||
        msg.contains('err_internet_disconnected');
  }

  /// Şəbəkə xətası aşkar edildikdə qlobal xəta səhifəsini aktiv edir
  void reportOffline() {
    if (!isOfflineNotifier.value) {
      isOfflineNotifier.value = true;
    }
  }

  /// Serverlə əlaqə uğurla qurulduqda offline səhifəsini bağlayır və yeniləmə siqnalı verir
  void reportOnline() {
    if (isOfflineNotifier.value) {
      isOfflineNotifier.value = false;
      reconnectNotifier.value++;
    }
  }

  /// Serverlə bağlantını yüngül HTTP sorğusu ilə test edir
  Future<bool> checkConnection() {
    if (_activeCheck != null) return _activeCheck!;
    _activeCheck = _performCheck().whenComplete(() {
      _activeCheck = null;
    });
    return _activeCheck!;
  }

  Future<bool> _performCheck() async {
    final checkDio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        validateStatus: (status) => status != null,
        headers: const {'Accept': 'application/json'},
      ),
    );

    try {
      final response = await checkDio.get<dynamic>(
        ApiEndpoints.termsAndConditionsGetAll,
        queryParameters: const {'languageCode': 'az'},
      );
      if (response.statusCode != null) {
        reportOnline();
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ [NETWORK MONITOR] Bağlantı yoxlanışı uğursuz oldu: $e');
    } finally {
      checkDio.close();
    }

    reportOffline();
    return false;
  }
}

