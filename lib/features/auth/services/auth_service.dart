import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/services/google_auth_service.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
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

class AuthService {
  final ApiClient _client = ApiClient.instance;

  // Köməkçi: Cavabdan token və refreshToken-i çıxarıb yaddaşa yazır
  bool _extractAndSaveTokens(dynamic responseData) {
    bool hasPin = false;
    if (responseData is Map) {
      final result = responseData['result'];
      String? token;
      String? refreshToken;

      if (result is Map) {
        token = (result['token'] ??
                result['accessToken'] ??
                result['jwtToken'])
            ?.toString();
        refreshToken = result['refreshToken']?.toString();
        if (result.containsKey('hasPinCode')) {
          hasPin = result['hasPinCode'] == true ||
              result['hasPinCode']?.toString().toLowerCase() == 'true';
        }
      }

      token ??= (responseData['token'] ??
              responseData['accessToken'] ??
              responseData['jwtToken'])
          ?.toString();
      refreshToken ??= responseData['refreshToken']?.toString();
      if (responseData.containsKey('hasPinCode')) {
        hasPin = responseData['hasPinCode'] == true ||
            responseData['hasPinCode']?.toString().toLowerCase() == 'true';
      }

      TokenStorage.setHasPinCode(hasPin);

      if (token != null && token.isNotEmpty) {
        debugPrint(
            '🔐 [TOKEN YADDAŞA YAZILDI]: ${token.substring(0, token.length > 15 ? 15 : token.length)}... (hasPinCode: $hasPin)');
        _client.setTokens(accessToken: token, refreshToken: refreshToken);
      } else {
        debugPrint('⚠️ [DİQQƏT]: Cavabda heç bir token tapılmadı! Data: $responseData');
      }
    }
    return hasPin;
  }

  // Giriş (Login) - LoginRequest modeli ilə
  Future<Response> login(LoginRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      _extractAndSaveTokens(response.data);
      return response;
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
      final response = await _client.post(
        ApiEndpoints.googleLogin,
        data: request.toJson(),
      );

      _extractAndSaveTokens(response.data);
      return response;
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

    debugPrint('==============================================');
    debugPrint('🔑 [POST /api/Auth/google-login GÖNDƏRİLİR]');
    debugPrint('🆔 Device ID   : $deviceId');
    debugPrint('📛 Device Name : $deviceName');
    debugPrint(
        '🎟️ idToken     : ${idToken.substring(0, idToken.length > 25 ? 25 : idToken.length)}...');
    debugPrint('==============================================');

    // 3. Backend-ə göndərilir və tokenlər avtomatik yaddaşa yazılır
    return await loginWithGoogle(
      GoogleLoginRequest(
        idToken: idToken,
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

      _extractAndSaveTokens(response.data);
      return response;
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

      debugPrint('🚪 [LOGOUT GÖNDƏRİLİR]');
      debugPrint('🔄 RefreshToken: $refreshToken');

      await _client.post(
        ApiEndpoints.logout,
        data: LogoutRequest(refreshToken: refreshToken).toJson(),
      );
    } catch (e) {
      debugPrint('⚠️ [LOGOUT API XƏTASI]: $e');
    } finally {
      await GoogleAuthService.signOut();
      _client.clearAuthToken();
      await TokenStorage.clearTokens();
      debugPrint('✅ [İSTİFADƏÇİ SESSIYASI TƏMİZLƏNDİ]');
    }
  }
}
