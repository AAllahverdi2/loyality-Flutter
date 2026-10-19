import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _secureStorage = FlutterSecureStorage();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserBarcode = 'user_barcode';
  static const _keyBiometricEnabled = 'biometric_auth_enabled';
  static const _keyBiometricPrompted = 'biometric_prompted_after_login';
  static const _keyPinCode = 'user_pin_code';
  static const _keyHasPinCode = 'user_has_pin_code';
  static const _keyUserFullName = 'user_full_name';
  static const _keyUserFirstName = 'user_first_name';
  static const _keyUserLastName = 'user_last_name';

  /// İstifadəçinin ad və soyadını yerli yaddaşda saxlayır
  static Future<void> saveUserName({
    String? firstName,
    String? lastName,
    String? fullName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (firstName != null && firstName.trim().isNotEmpty) {
        await prefs.setString(_keyUserFirstName, firstName.trim());
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        await prefs.setString(_keyUserLastName, lastName.trim());
      }
      if (fullName != null && fullName.trim().isNotEmpty) {
        await prefs.setString(_keyUserFullName, fullName.trim());
      } else {
        final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
        if (combined.isNotEmpty) {
          await prefs.setString(_keyUserFullName, combined);
        }
      }
    } catch (_) {}
  }

  /// İstifadəçinin ad və soyadını qaytarır
  static Future<String?> getUserFullName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString(_keyUserFullName);
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
      final firstName = prefs.getString(_keyUserFirstName);
      final lastName = prefs.getString(_keyUserLastName);
      final combined = '${firstName ?? ''} ${lastName ?? ''}'.trim();
      if (combined.isNotEmpty) return combined;
    } catch (_) {}
    return null;
  }

  /// Tokenləri təhlükəsiz şəkildə (Secure Storage və SharedPreferences) saxlayır
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      await _secureStorage.write(key: _keyAccessToken, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
      }
    } catch (e) {
      debugPrint('⚠️ [TokenStorage] Secure storage write error: $e');
    }

    // Geriye uyğunluq üçün SharedPreferences-ə də yazırıq
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await prefs.setString(_keyRefreshToken, refreshToken);
      }
    } catch (_) {}
  }

  /// Access Token-i oxuyur (Əvvəlcə SecureStorage, tapılmazsa SharedPreferences)
  static Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _keyAccessToken);
      if (token != null && token.trim().isNotEmpty) {
        return token;
      }
    } catch (e) {
      debugPrint('⚠️ [TokenStorage] Secure storage read error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyAccessToken);
      // Köhnə versiyadan gələn tokeni avtomatik SecureStorage-ə miqrasiya edirik
      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: _keyAccessToken, value: token);
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Refresh Token-i oxuyur
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _keyRefreshToken);
      if (token != null && token.trim().isNotEmpty) {
        return token;
      }
    } catch (e) {
      debugPrint('⚠️ [TokenStorage] Secure storage read error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyRefreshToken);
      if (token != null && token.isNotEmpty) {
        await _secureStorage.write(key: _keyRefreshToken, value: token);
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Cari aktiv sessiyanın mövcudluğunu yoxlayır
  static Future<bool> hasValidSession() async {
    final access = await getAccessToken();
    if (access != null && access.trim().isNotEmpty) return true;
    final refresh = await getRefreshToken();
    return refresh != null && refresh.trim().isNotEmpty;
  }

  static Future<void> saveBarcode(String barcode) async {
    try {
      await _secureStorage.write(key: _keyUserBarcode, value: barcode);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserBarcode, barcode);
  }

  static Future<String?> getBarcode() async {
    try {
      final b = await _secureStorage.read(key: _keyUserBarcode);
      if (b != null && b.isNotEmpty) return b;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserBarcode);
  }

  /// İstifadəçinin biometrik girişi aktiv edib-etmədiyini oxuyur
  static Future<bool> isBiometricEnabled() async {
    try {
      final val = await _secureStorage.read(key: _keyBiometricEnabled);
      if (val != null) {
        return val == 'true';
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// İstifadəçinin biometrik giriş seçimini saxlayır
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _keyBiometricEnabled,
        value: enabled ? 'true' : 'false',
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// İstifadəçiyə biometrika təklif edilib-edilmədiyini yoxlayır
  static Future<bool> hasPromptedBiometric() async {
    try {
      final val = await _secureStorage.read(key: _keyBiometricPrompted);
      if (val != null) return val == 'true';
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricPrompted) ?? false;
  }

  /// İlk girişdə təklif edildiyini qeyd edir
  static Future<void> setPromptedBiometric(bool prompted) async {
    try {
      await _secureStorage.write(
        key: _keyBiometricPrompted,
        value: prompted ? 'true' : 'false',
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricPrompted, prompted);
  }

  /// İstifadəçinin təyin etdiyi 4 rəqəmli PIN kodu saxlayır
  static Future<void> setPinCode(String pin) async {
    await setHasPinCode(true);
    try {
      await _secureStorage.write(key: _keyPinCode, value: pin);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinCode, pin);
  }

  /// Serverdən gələn PIN kod mövcudluğu statusunu saxlayır
  static Future<void> setHasPinCode(bool hasPin) async {
    try {
      await _secureStorage.write(
        key: _keyHasPinCode,
        value: hasPin ? 'true' : 'false',
      );
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasPinCode, hasPin);
    if (!hasPin) {
      await removePinCode();
    }
  }

  /// Yaddaşdakı PIN kodu oxuyur
  static Future<String?> getPinCode() async {
    try {
      final pin = await _secureStorage.read(key: _keyPinCode);
      if (pin != null && pin.isNotEmpty) return pin;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPinCode);
  }

  /// PIN kodun təyin edilib-edilmədiyini yoxlayır
  static Future<bool> hasPinCode() async {
    try {
      final val = await _secureStorage.read(key: _keyHasPinCode);
      if (val != null) {
        return val == 'true';
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_keyHasPinCode)) {
      return prefs.getBool(_keyHasPinCode) ?? false;
    }
    final pin = await getPinCode();
    return pin != null && pin.trim().isNotEmpty;
  }

  /// PIN kodu silir
  static Future<void> removePinCode() async {
    try {
      await _secureStorage.delete(key: _keyPinCode);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinCode);
  }

  /// Çıxış zamanı bütün sessiya məlumatlarını və tokenləri silir
  static Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _keyAccessToken);
      await _secureStorage.delete(key: _keyRefreshToken);
      await _secureStorage.delete(key: _keyUserBarcode);
      await _secureStorage.delete(key: _keyBiometricEnabled);
      await _secureStorage.delete(key: _keyBiometricPrompted);
      await _secureStorage.delete(key: _keyPinCode);
      await _secureStorage.delete(key: _keyHasPinCode);
    } catch (e) {
      debugPrint('⚠️ [TokenStorage] Clear secure storage error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserBarcode);
      await prefs.remove(_keyBiometricEnabled);
      await prefs.remove(_keyBiometricPrompted);
      await prefs.remove(_keyPinCode);
      await prefs.remove(_keyHasPinCode);
      await prefs.remove(_keyUserFullName);
      await prefs.remove(_keyUserFirstName);
      await prefs.remove(_keyUserLastName);
    } catch (_) {}
  }
}
