import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleCredentialData {
  const AppleCredentialData({
    required this.identityToken,
    this.firstName,
    this.lastName,
  });

  final String identityToken;
  final String? firstName;
  final String? lastName;
}

class AppleAuthService {
  static const String _cachePrefixFirst = 'apple_first_name_';
  static const String _cachePrefixLast = 'apple_last_name_';

  /// Apple hesab seçicisini açır və identityToken (+ ilk girişdə ad/soyad) qaytarır.
  /// İstifadəçi pəncərəni bağlayarsa null qaytarır.
  static Future<AppleCredentialData?> signInAndGetCredential() async {
    if (kIsWeb || (!Platform.isIOS && !Platform.isMacOS)) {
      throw Exception(tr('auth_apple_not_available'));
    }

    final isAvailable = await SignInWithApple.isAvailable();
    if (!isAvailable) {
      throw Exception(tr('auth_apple_not_available'));
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken?.trim();
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception(tr('auth_apple_auth_failed'));
      }

      String? firstName = credential.givenName?.trim();
      String? lastName = credential.familyName?.trim();
      if (firstName != null && firstName.isEmpty) firstName = null;
      if (lastName != null && lastName.isEmpty) lastName = null;

      final userKey = credential.userIdentifier?.trim();
      if (userKey != null && userKey.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          // Apple ad/soyadı yalnız ilk girişdə qaytarır; şəbəkə xətası olarsa
          // təkrar cəhddə itməməsi üçün lokalda keşləyirik.
          if (firstName != null) {
            await prefs.setString('$_cachePrefixFirst$userKey', firstName);
          } else {
            firstName = prefs.getString('$_cachePrefixFirst$userKey');
          }
          if (lastName != null) {
            await prefs.setString('$_cachePrefixLast$userKey', lastName);
          } else {
            lastName = prefs.getString('$_cachePrefixLast$userKey');
          }
        } catch (_) {}
      }

      return AppleCredentialData(
        identityToken: identityToken,
        firstName: firstName,
        lastName: lastName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return null;
      }
      throw Exception(
        e.message.trim().isNotEmpty
            ? e.message.trim()
            : tr('auth_apple_auth_failed'),
      );
    } on SignInWithAppleNotSupportedException {
      throw Exception(tr('auth_apple_not_available'));
    }
  }
}
