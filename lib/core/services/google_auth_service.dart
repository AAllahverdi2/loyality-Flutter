import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loyallig_flutter/core/constants/google_auth_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initFuture;

  /// Plugin-i platformaya uyğun konfiqurasiya edir.
  static Future<void> _ensureInitialized() {
    return _initFuture ??= _initializeInternal();
  }

  static Future<void> _initializeInternal() async {
    final String serverClientId = GoogleAuthConfig.cleanWebClientId;
    if (serverClientId.isEmpty) {
      _initFuture = null;
      throw Exception(
        'Google ilə daxil olmaq üçün Web Client ID qeyd edilməlidir. '
        'Zəhmət olmasa "lib/core/constants/google_auth_config.dart" faylındakı '
        'GoogleAuthConfig.webClientId dəyərinə Google Cloud Web Client ID-nizi yazın.',
      );
    }

    try {
      if (kIsWeb) {
        await _googleSignIn.initialize(clientId: serverClientId);
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        await _googleSignIn.initialize(serverClientId: serverClientId);
        return;
      }

      final String? iosClientId = GoogleAuthConfig.iosClientId.trim().isNotEmpty
          ? GoogleAuthConfig.iosClientId.trim()
          : null;

      await _googleSignIn.initialize(
        serverClientId: serverClientId,
        clientId: iosClientId,
      );
    } catch (_) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Google hesab seçicisini açır və dinamik idToken əldə edir.
  /// İstifadəçi pəncərəni bağlayarsa null qaytarır.
  static Future<String?> signInAndGetIdToken() async {
    try {
      await _ensureInitialized();

      if (kIsWeb || !_googleSignIn.supportsAuthenticate()) {
        throw Exception(
          'Google ilə giriş yalnız Android və iOS mobil tətbiqində dəstəklənir.',
        );
      }

      // İstifadəçiyə yenidən hesab seçmə şansı vermək üçün əvvəlki yerli sessiyanı təmizləyirik
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      if (kDebugMode) {
        debugPrint(
          '🔵 [GOOGLE SIGN IN]: authenticate() başlayır (platform=${defaultTargetPlatform.name}, serverClientId=${GoogleAuthConfig.cleanWebClientId})',
        );
      }

      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint(
            '⚠️ [GOOGLE SIGN IN]: idToken null qayıtdı! serverClientId (Web Client ID) təyin olunmalıdır.');
        throw Exception(
          'Google idToken alına bilmədi. Zəhmət olmasa GoogleAuthConfig.webClientId konfiqurasiyasını yoxlayın.',
        );
      }

      if (kDebugMode) {
        _logIdTokenClaims(idToken);
      }

      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('ℹ️ [GOOGLE SIGN IN]: İstifadəçi pəncərəni bağladı.');
        return null;
      }
      debugPrint('❌ [GOOGLE SIGN IN XƏTASI]: ${e.code} - ${e.description}');
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError) {
        throw Exception(
          'Google konfiqurasiya xətası: Web Client ID və ya SHA-1 barmaq izi Google Cloud-da düzgün qeyd olunmayıb.',
        );
      }
      throw Exception(
        e.description ?? 'Google ilə giriş zamanı xəta baş verdi (${e.code.name}).',
      );
    } catch (e) {
      debugPrint('❌ [GOOGLE SIGN IN XƏTASI]: $e');
      rethrow;
    }
  }

  /// Google sessiyasından çıxış
  static Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  static void _logIdTokenClaims(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length < 2) {
        debugPrint('🟢 [GOOGLE SIGN IN]: idToken alındı (len=${idToken.length})');
        return;
      }
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payloadJson) as Map<String, dynamic>;
      debugPrint(
        '🟢 [GOOGLE SIGN IN]: idToken alındı (len=${idToken.length}, aud=${claims['aud']}, azp=${claims['azp']}, iss=${claims['iss']})',
      );
    } catch (_) {
      debugPrint('🟢 [GOOGLE SIGN IN]: idToken alındı (len=${idToken.length})');
    }
  }
}
