import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';

enum BiometricAuthStatus {
  success,
  failed,
  canceled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}

class BiometricAuthResult {
  const BiometricAuthResult({
    required this.status,
    this.errorMessage,
  });

  final BiometricAuthStatus status;
  final String? errorMessage;

  bool get isSuccess => status == BiometricAuthStatus.success;
}

class BiometricService {
  BiometricService._internal();
  static final BiometricService instance = BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticating = false;

  bool get isAuthenticating => _isAuthenticating;

  /// Cihazın biometrik sensoru (Face ID / Barmaq izi) dəstəkləyib-dəstəkləmədiyini yoxlayır
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (e) {
      debugPrint('⚠️ [BiometricService] isDeviceSupported xətası: $e');
      return false;
    }
  }

  /// Cihazın biometrika yoxlamağa qadir olub-olmadığını yoxlayır
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('⚠️ [BiometricService] canCheckBiometrics xətası: $e');
      return false;
    }
  }

  /// Cihazda qeydiyyatdan keçmiş biometrika növlərini gətirir
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('⚠️ [BiometricService] getAvailableBiometrics xətası: $e');
      return [];
    }
  }

  /// Cihazda ən azı bir barmaq izi və ya Face ID qeydiyyatdan keçibmi?
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final biometrics = await _localAuth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ [BiometricService] hasEnrolledBiometrics xətası: $e');
      return false;
    }
  }

  /// Həm sensor var, həm də istifadəçi biometrika qeyd edib
  Future<bool> canUseBiometrics() async {
    final supported = await isDeviceSupported();
    if (!supported) return false;
    return await hasEnrolledBiometrics();
  }

  /// İstifadəçi interfeysi üçün biometrika növünün adı (məs. "Face ID" və ya "Barmaq izi")
  Future<String> getBiometricDisplayName() async {
    try {
      final biometrics = await getAvailableBiometrics();
      if (Platform.isIOS) {
        if (biometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        }
      } else {
        if (biometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Barmaq izi';
        }
      }
    } catch (_) {}
    return 'Biometrik giriş';
  }

  /// İstifadəçinin biometrik girişi aktiv edib-etmədiyini yoxlayır
  Future<bool> isBiometricEnabled() async {
    return await TokenStorage.isBiometricEnabled();
  }

  /// İstifadəçinin biometrik giriş seçimini yaddaşa yazır
  Future<void> setBiometricEnabled(bool enabled) async {
    await TokenStorage.setBiometricEnabled(enabled);
  }

  /// İstifadəçiyə ilk girişdən sonra biometrik seçim dialoqunun göstərildiyini yoxlayır
  Future<bool> hasPromptedBiometric() async {
    return await TokenStorage.hasPromptedBiometric();
  }

  /// İlk giriş dialoqunun göstərildiyini qeyd edir
  Future<void> setPromptedBiometric(bool prompted) async {
    await TokenStorage.setPromptedBiometric(prompted);
  }

  /// Biometrik identifikasiya sorğusu göndərir
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = true,
  }) async {
    if (_isAuthenticating) {
      return const BiometricAuthResult(
        status: BiometricAuthStatus.canceled,
        errorMessage: 'İdentifikasiya artıq icra olunur.',
      );
    }

    _isAuthenticating = true;

    try {
      final canAuth = await canUseBiometrics();
      if (!canAuth) {
        final supported = await isDeviceSupported();
        if (!supported) {
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notAvailable,
            errorMessage: 'Cihazınızda biometrik sensor mövcud deyil.',
          );
        }
        return const BiometricAuthResult(
          status: BiometricAuthStatus.notEnrolled,
          errorMessage:
              'Cihazınızda heç bir Face ID və ya barmaq izi qeydiyyatdan keçməyib.',
        );
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: true,
        sensitiveTransaction: true,
      );

      if (didAuthenticate) {
        debugPrint('✅ [BiometricService] İdentifikasiya uğurlu oldu!');
        return const BiometricAuthResult(status: BiometricAuthStatus.success);
      } else {
        debugPrint(
            '❌ [BiometricService] İdentifikasiya ləğv edildi və ya uğursuz oldu.');
        return const BiometricAuthResult(status: BiometricAuthStatus.canceled);
      }
    } on LocalAuthException catch (e) {
      debugPrint('🚨 [BiometricService] LocalAuthException: ${e.code} - ${e.description}');
      switch (e.code) {
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notAvailable,
            errorMessage: 'Biometrik giriş hazırda əlçatan deyil.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noCredentialsSet:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notEnrolled,
            errorMessage: 'Cihazınızda qeydiyyatdan keçmiş biometrika yoxdur.',
          );
        case LocalAuthExceptionCode.temporaryLockout:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.lockedOut,
            errorMessage: 'Həddən artıq uğursuz cəhd. Cihaz müvəqqəti bloklanıb.',
          );
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.permanentlyLockedOut,
            errorMessage:
                'Biometrika tam bloklanıb. Cihazın ekran şifrəsini daxil edin.',
          );
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.authInProgress:
          return const BiometricAuthResult(
            status: BiometricAuthStatus.canceled,
            errorMessage: 'Əməliyyat ləğv edildi.',
          );
        default:
          return BiometricAuthResult(
            status: BiometricAuthStatus.failed,
            errorMessage: e.description ?? 'Biometrik identifikasiya xətası.',
          );
      }
    } on PlatformException catch (e) {
      debugPrint('🚨 [BiometricService] PlatformException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'NotAvailable':
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notAvailable,
            errorMessage: 'Biometrik giriş hazırda əlçatan deyil.',
          );
        case 'NotEnrolled':
          return const BiometricAuthResult(
            status: BiometricAuthStatus.notEnrolled,
            errorMessage: 'Cihazınızda qeydiyyatdan keçmiş biometrika yoxdur.',
          );
        case 'LockedOut':
          return const BiometricAuthResult(
            status: BiometricAuthStatus.lockedOut,
            errorMessage: 'Həddən artıq uğursuz cəhd. Cihaz müvəqqəti bloklanıb.',
          );
        case 'PermanentlyLockedOut':
          return const BiometricAuthResult(
            status: BiometricAuthStatus.permanentlyLockedOut,
            errorMessage: 'Biometrika tam bloklanıb. Cihazın ekran şifrəsini daxil edin.',
          );
        case 'UserCanceled':
        case 'auth_in_progress':
          return const BiometricAuthResult(
            status: BiometricAuthStatus.canceled,
            errorMessage: 'Əməliyyat ləğv edildi.',
          );
        default:
          return BiometricAuthResult(
            status: BiometricAuthStatus.failed,
            errorMessage: e.message ?? 'Biometrik identifikasiya xətası.',
          );
      }
    } catch (e) {
      debugPrint('🚨 [BiometricService] Gözlənilməz xəta: $e');
      return BiometricAuthResult(
        status: BiometricAuthStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isAuthenticating = false;
    }
  }

  /// Davam edən identifikasiyanı dayandırmaq
  Future<void> cancelAuthentication() async {
    try {
      if (_isAuthenticating) {
        await _localAuth.stopAuthentication();
      }
    } catch (_) {}
    _isAuthenticating = false;
  }
}
