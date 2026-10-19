import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/main.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Auth & Auto-Refresh Token Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dil başlığı
          options.headers['Accept-Language'] = AppLocalizations.currentLanguageCode;

          // Əgər token hələ RAM-da yoxdursa, storage-dən oxuyuruq
          if (_accessToken == null || _accessToken!.isEmpty) {
            _accessToken = await TokenStorage.getAccessToken();
            _refreshToken = await TokenStorage.getRefreshToken();
          }

          // Əgər Access Token varsa, Authorization başlığına 'Bearer <token>' əlavə edirik
          if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
            String token = _accessToken!.trim();
            if (token.startsWith('Bearer ')) {
              token = token.substring(7).trim();
            }
            options.headers['Authorization'] = 'Bearer $token';
            debugPrint(
                '🔑 [AUTHORIZATION HEADER]: Bearer ${token.substring(0, token.length > 25 ? 25 : token.length)}...');
          } else {
            debugPrint(
                '⚠️ [TOKEN YOXDUR]: ${options.path} üçün Access Token tapılmadı (İstifadəçi daxil olmayıb və ya çıxış edib)');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // 401 Unauthorized: Access Token-in vaxtı bitdikdə və ya etibarsız olduqda
          if (error.response?.statusCode == 401) {
            debugPrint('🚨 [401 UNAUTHORIZED]: ${error.requestOptions.path}');
            debugPrint('   Headers: ${error.requestOptions.headers}');
            debugPrint('   Response Data: ${error.response?.data}');

            // Əgər sorğu artıq bir dəfə təkrar olunubsa və yenə 401 alıbsa, Login-ə yönləndiririk
            if (error.requestOptions.extra['retried'] == true) {
              _handleAuthFailure();
              return handler.next(error);
            }

            final path = error.requestOptions.path;
            final isAuthEndpoint = path.contains('/api/Auth/') ||
                path.contains(ApiEndpoints.refreshToken) ||
                path.contains(ApiEndpoints.login) ||
                path.contains(ApiEndpoints.logout);

            // Əgər refresh token endpoint-i özü 401 alıbsa, dərhal Login-ə atırıq
            if (path.contains(ApiEndpoints.refreshToken) || path.contains('/refreshToken')) {
              debugPrint('🚨 [REFRESH TOKEN İSTİFADƏ MÜDDƏTİ BİTİB (401) - LOGIN-Ə YÖNLƏNDİRİLİR]');
              _handleAuthFailure();
              return handler.next(error);
            }

            // Əgər auth endpoint deyilsə
            if (!isAuthEndpoint) {
              // Əgər əlimizdə heç Refresh Token yoxdursa, birbaşa Login-ə atırıq
              if (_refreshToken == null || _refreshToken!.trim().isEmpty) {
                debugPrint('⚠️ [REFRESH TOKEN YOXDUR - LOGIN-Ə YÖNLƏNDİRİLİR]');
                _handleAuthFailure();
                return handler.next(error);
              }

              debugPrint('🔄 [ACCESS TOKEN BİTİB (401) - REFRESH TOKEN İŞƏ DÜŞÜR]');

              final refreshed = await _refreshAccessToken();
              if (refreshed && _accessToken != null && _accessToken!.trim().isNotEmpty) {
                String token = _accessToken!.trim();
                if (token.startsWith('Bearer ')) {
                  token = token.substring(7).trim();
                }

                // Orijinal sorğunu yeni Access Token ilə təkrar göndəririk
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $token';
                options.extra['retried'] = true; // Təkrar dövrənin qarşısını alırıq

                try {
                  final retryResponse = await _dio.fetch(options);
                  return handler.resolve(retryResponse);
                } catch (e) {
                  return handler.next(error);
                }
              } else {
                // Refresh token uğursuz olduqda dərhal Login-ə yönləndiririk
                _handleAuthFailure();
                return handler.next(error);
              }
            }
          }
          return handler.next(error);
        },
      ),
    );

    // 2. Logging Interceptor (Bütün başlıqlar konsolda görünür)
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );

    // Başlanğıcda yaddaşdan tokenləri oxuyuruq
    _initTokensFromStorage();
  }

  static final ApiClient instance = ApiClient._internal();
  late final Dio _dio;
  String? _accessToken;
  String? _refreshToken;
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;
  static DateTime? _lastRedirectTime;

  Dio get dio => _dio;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Map<String, String> get authHeaders {
    if (_accessToken != null && _accessToken!.trim().isNotEmpty) {
      String token = _accessToken!.trim();
      if (token.startsWith('Bearer ')) {
        token = token.substring(7).trim();
      }
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  Future<void> _initTokensFromStorage() async {
    _accessToken = await TokenStorage.getAccessToken();
    _refreshToken = await TokenStorage.getRefreshToken();
  }

  // Tokenləri həm yaddaşda (RAM), həm də yerli yaddaşda (Storage) saxlayır
  void setTokens({
    required String accessToken,
    String? refreshToken,
  }) {
    _accessToken = accessToken;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }
    TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: _refreshToken,
    );
  }

  void setAuthToken(String token) {
    setTokens(accessToken: token);
  }

  // Bütün tokenləri silmək (Çıxış zamanı)
  void clearAuthToken() {
    _accessToken = null;
    _refreshToken = null;
    TokenStorage.clearTokens();
  }

  // İstifadəçini çıxarıb Login ekranına yönləndirmək
  static void redirectToLogin() {
    instance.clearAuthToken();

    final now = DateTime.now();
    if (_lastRedirectTime != null &&
        now.difference(_lastRedirectTime!) < const Duration(seconds: 2)) {
      return;
    }
    _lastRedirectTime = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    });
  }

  void _handleAuthFailure() {
    redirectToLogin();
  }

  // 10 dəqiqəlik Access Token bitdikdə arxa planda yeni token almaq
  Future<bool> _refreshAccessToken() async {
    // Əgər paralel digər sorğu artıq refresh edirsə, onun cavabını gözləyirik
    if (_isRefreshing && _refreshCompleter != null) {
      return await _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();

      String cleanAccessToken = _accessToken?.trim() ?? '';
      if (cleanAccessToken.startsWith('Bearer ')) {
        cleanAccessToken = cleanAccessToken.substring(7).trim();
      }

      String cleanRefreshToken = _refreshToken?.trim() ?? '';
      if (cleanRefreshToken.startsWith('Bearer ')) {
        cleanRefreshToken = cleanRefreshToken.substring(7).trim();
      }

      // Sonsuz dövrə düşməsin deyə ayrı müstəqil Dio çağırışı edirik
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: ApiEndpoints.connectTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {
          'accessToken': cleanAccessToken,
          'refreshToken': cleanRefreshToken,
          'deviceId': deviceId,
          'deviceName': deviceName,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final result = response.data['result'];
        final newToken = result != null && result is Map
            ? (result['token'] ??
                    result['accessToken'] ??
                    result['jwtToken'])
                ?.toString()
            : (response.data['token'] ??
                    response.data['accessToken'] ??
                    response.data['jwtToken'])
                ?.toString();
        final newRefreshToken = result != null && result is Map
            ? result['refreshToken']?.toString()
            : response.data['refreshToken']?.toString();

        if (newToken != null && newToken.isNotEmpty) {
          setTokens(
            accessToken: newToken,
            refreshToken: newRefreshToken ?? _refreshToken,
          );
          if (result != null && result is Map && result.containsKey('hasPinCode')) {
            final hasPin = result['hasPinCode'] == true ||
                result['hasPinCode']?.toString().toLowerCase() == 'true';
            TokenStorage.setHasPinCode(hasPin);
          } else if (response.data is Map && response.data.containsKey('hasPinCode')) {
            final hasPin = response.data['hasPinCode'] == true ||
                response.data['hasPinCode']?.toString().toLowerCase() == 'true';
            TokenStorage.setHasPinCode(hasPin);
          }
          debugPrint('✅ [TOKEN UĞURLA YENİLƏNDİ!]');
          _refreshCompleter?.complete(true);
          return true;
        }
      }

      _refreshCompleter?.complete(false);
      return false;
    } catch (e) {
      debugPrint('❌ [REFRESH TOKEN XƏTASI]: $e');
      _refreshCompleter?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  // GET sorğusu
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST sorğusu
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT sorğusu
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE sorğusu
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
