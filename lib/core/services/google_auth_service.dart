import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loyallig_flutter/core/constants/google_auth_config.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _initialized = false;

  /// Plugin-i konfiqurasiya edir (Web Client ID təyin olunur).
  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    final String serverClientId = GoogleAuthConfig.cleanWebClientId;
    if (serverClientId.isEmpty) {
      throw Exception(
        'Google ilə daxil olmaq üçün Web Client ID qeyd edilməlidir. '
        'Zəhmət olmasa "lib/core/constants/google_auth_config.dart" faylındakı '
        'GoogleAuthConfig.webClientId dəyərinə Google Cloud Web Client ID-nizi yazın.',
      );
    }

    final String? clientId = GoogleAuthConfig.iosClientId.trim().isNotEmpty
        ? GoogleAuthConfig.iosClientId.trim()
        : null;

    await _googleSignIn.initialize(
      serverClientId: serverClientId,
      clientId: clientId,
    );
    _initialized = true;
  }

  /// Google hesab seçicisini açır və dinamik idToken əldə edir.
  /// İstifadəçi pəncərəni bağlayarsa null qaytarır.
  static Future<String?> signInAndGetIdToken() async {
    try {
      await _ensureInitialized();

      // İstifadəçiyə yenidən hesab seçmə şansı vermək üçün əvvəlki yerli sessiyanı təmizləyirik
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

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
}
