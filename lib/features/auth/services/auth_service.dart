import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/services/apple_auth_service.dart';
import 'package:loyallig_flutter/core/services/google_auth_service.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/auth/models/apple_login_request.dart';
import 'package:loyallig_flutter/features/auth/models/change_password_request.dart';
import 'package:loyallig_flutter/features/auth/models/forgot_password_request.dart';
import 'package:loyallig_flutter/features/auth/models/google_login_request.dart';
import 'package:loyallig_flutter/features/auth/models/login_request.dart';
import 'package:loyallig_flutter/features/auth/models/logout_request.dart';
import 'package:loyallig_flutter/features/auth/models/refresh_token_request.dart';
import 'package:loyallig_flutter/features/auth/models/register_request.dart';
import 'package:loyallig_flutter/features/auth/models/reset_password_request.dart';
import 'package:loyallig_flutter/features/auth/models/send_register_code_request.dart';
import 'package:loyallig_flutter/features/auth/models/verify_reset_code_request.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_conversations_store.dart';
import 'package:loyallig_flutter/features/discounts/services/discounts_service.dart';
import 'package:loyallig_flutter/features/history/services/transaction_service.dart';
import 'package:loyallig_flutter/features/history/services/wallet_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_hub_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/features/notifications/services/push_notification_service.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  /// İstifadəçi dəyişdikdə və ya çıxış etdikdə bütün RAM və lokal istifadəçi keşlərini təmizləyir
  Future<void> _resetUserCaches() async {
    ProfileService.clearCache();
    WalletService.clearCache();
    PartnersService.clearCache();
    TransactionService.clearLookupsCache();
    DiscountsService.clearLookupsCache();
    SupportConversationsStore.instance.clear();
    NotificationsStore.instance.clear();
    await TokenStorage.clearCachedUserProfileData();
  }

  // Köməkçi: Cavabdan token və refreshToken-i çıxarıb yaddaşa yazır
  bool _extractAndSaveTokens(dynamic responseData) {
    bool hasPin = false;
    if (responseData is Map) {
      final result = responseData['result'] ?? responseData['data'];
      String? token;
      String? refreshToken;

      if (result is Map) {
        token = (result['token'] ?? result['accessToken'] ?? result['jwtToken'])
            ?.toString();
        refreshToken = result['refreshToken']?.toString();
        if (result.containsKey('hasPinCode')) {
          hasPin =
              result['hasPinCode'] == true ||
              result['hasPinCode']?.toString().toLowerCase() == 'true';
        }
      }

      token ??=
          (responseData['token'] ??
                  responseData['accessToken'] ??
                  responseData['jwtToken'])
              ?.toString();
      refreshToken ??= responseData['refreshToken']?.toString();
      if (responseData.containsKey('hasPinCode')) {
        hasPin =
            responseData['hasPinCode'] == true ||
            responseData['hasPinCode']?.toString().toLowerCase() == 'true';
      }

      TokenStorage.setHasPinCode(hasPin);

      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('🔐 [TOKEN YADDAŞA YAZILDI]: hasPinCode=$hasPin');
        }
        _client.setTokens(accessToken: token, refreshToken: refreshToken);
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ [DİQQƏT]: Cavabda token tapılmadı.');
        }
      }
    }
    return hasPin;
  }

  Future<Response> _applyAuthSessionResponse(
    Response response, {
    required String fallbackError,
  }) async {
    if (response.data is Map && response.data['isSuccess'] == false) {
      final errors = response.data['errors'];
      final message = (errors is List && errors.isNotEmpty)
          ? errors.first?.toString()
          : (response.data['message'] ?? response.data['errorMessage'])
              ?.toString();
      throw Exception(
        (message != null && message.trim().isNotEmpty)
            ? message.trim()
            : fallbackError,
      );
    }

    await SupportChatHubService.instance.stop();
    await NotificationsHubService.instance.stop();
    await _resetUserCaches();
    _extractAndSaveTokens(response.data);
    unawaited(SupportConversationsStore.instance.initGlobalSession());
    unawaited(NotificationsStore.instance.initGlobalSession());
    unawaited(
      PushNotificationService.instance.syncSessionPushSettings(
        enabled: NotificationsStore.instance.isNotificationsEnabled,
        force: true,
      ),
    );
    return response;
  }

  // Giriş (Login) - LoginRequest modeli ilə
  Future<Response> login(LoginRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );
      return await _applyAuthSessionResponse(
        response,
        fallbackError: 'Giriş uğursuz oldu.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Giriş üçün köməkçi rahat metod
  Future<Response> loginWithFields({
    required String email,
    required String password,
    required String deviceId,
    required String deviceName,
  }) async {
    return login(
      LoginRequest(
        email: email,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );
  }

  // Google ilə Giriş API Sorğusu (/api/Auth/google-login)
  Future<Response> loginWithGoogle(GoogleLoginRequest request) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '🌐 [GOOGLE LOGIN] POST ${ApiEndpoints.baseUrl}${ApiEndpoints.googleLogin}',
        );
      }
      final response = await _client.post(
        ApiEndpoints.googleLogin,
        data: request.toJson(),
      );
      if (kDebugMode) {
        debugPrint(
          '✅ [GOOGLE LOGIN] status=${response.statusCode} uri=${response.requestOptions.uri}',
        );
      }
      return await _applyAuthSessionResponse(
        response,
        fallbackError: 'Google ilə giriş uğursuz oldu.',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '❌ [GOOGLE LOGIN API XƏTASI]: type=${e.type.name} status=${e.response?.statusCode} uri=${e.requestOptions.uri} msg=${e.message} err=${e.error} body=${e.response?.data}',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // Google Giriş Bütöv Flow (Hesab seçimi -> idToken -> Cihaz məlumatları -> Backend API)
  Future<Response?> signInWithGoogle() async {
    // 1. Google hesab seçicisi açılır və idToken əldə edilir
    final idToken = await GoogleAuthService.signInAndGetIdToken();
    if (idToken == null) {
      return null; // İstifadəçi pəncərəni bağladı
    }

    // 2. Mövcud real cihaz məlumatları
    final deviceId = await DeviceHelper.getDeviceId();
    final deviceName = await DeviceHelper.getDeviceName();

    // 3. Backend-ə göndərilir və tokenlər avtomatik yaddaşa yazılır
    return await loginWithGoogle(
      GoogleLoginRequest(
        idToken: idToken,
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );
  }

  // Apple ilə Giriş API Sorğusu (/api/auth/apple-login)
  Future<Response> loginWithApple(AppleLoginRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.appleLogin,
        data: request.toJson(),
      );
      return await _applyAuthSessionResponse(
        response,
        fallbackError: 'Apple ilə giriş uğursuz oldu.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Apple Giriş Bütöv Flow (Apple Credential -> Cihaz məlumatları -> Backend API)
  Future<Response?> signInWithApple() async {
    final credential = await AppleAuthService.signInAndGetCredential();
    if (credential == null) {
      return null; // İstifadəçi pəncərəni bağladı
    }

    final deviceId = await DeviceHelper.getDeviceId();
    final deviceName = await DeviceHelper.getDeviceName();

    return await loginWithApple(
      AppleLoginRequest(
        identityToken: credential.identityToken,
        firstName: credential.firstName,
        lastName: credential.lastName,
        deviceId: deviceId,
        deviceName: deviceName,
      ),
    );
  }

  // Qeydiyyat Kodu Göndərmək (Step 1: /api/Auth/sendRegisterCode)
  Future<Response> sendRegisterCode(SendRegisterCodeRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.sendRegisterCode,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // sendRegisterCode üçün köməkçi rahat metod
  Future<Response> sendRegisterCodeWithFields({
    required String email,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
  }) async {
    return sendRegisterCode(
      SendRegisterCodeRequest(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  // Qeydiyyatı tamamlamaq və kodu təsdiqləmək (Step 2: /api/Auth/register)
  Future<Response> register(RegisterRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );
      return await _applyAuthSessionResponse(
        response,
        fallbackError: 'Qeydiyyat uğursuz oldu.',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Refresh Token Xidməti (/api/Auth/refreshToken)
  Future<Response> refreshToken(RefreshTokenRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.refreshToken,
        data: request.toJson(),
      );

      _extractAndSaveTokens(response.data);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Şifrəni unutdum (Step 1: /api/Auth/forgotPassword)
  Future<Response> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.forgotPassword,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Şifrə sıfırlama kodunu təsdiqləmək (Step 2: /api/Auth/verifyResetCode)
  Future<Response> verifyResetCode(VerifyResetCodeRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.verifyResetCode,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Yeni şifrəni təyin etmək (Step 3: /api/Auth/resetPassword)
  Future<Response> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.resetPassword,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Cari şifrəni dəyişmək (/api/Auth/changePassword)
  Future<Response> changePassword(ChangePasswordRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.changePassword,
        data: request.toJson(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Çıxış (Logout - /api/Auth/logout)
  Future<void> logout() async {
    try {
      final refreshToken =
          _client.refreshToken ?? await TokenStorage.getRefreshToken() ?? '';

      await _client.post(
        ApiEndpoints.logout,
        data: LogoutRequest(refreshToken: refreshToken).toJson(),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [LOGOUT API XƏTASI]: ${e.runtimeType}');
      }
    } finally {
      await PushNotificationService.instance.unregisterDeviceToken();
      await SupportChatHubService.instance.stop();
      await NotificationsHubService.instance.stop();
      await _resetUserCaches();
      await GoogleAuthService.signOut();
      _client.clearAuthToken();
      await TokenStorage.clearTokens();
    }
  }
}
