import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';
import 'package:loyallig_flutter/features/profile/pin_code_settings_screen.dart';

class SocialAuthHelper {
  SocialAuthHelper._();

  static Future<void> navigateAfterAuth(BuildContext context) async {
    final hasPin = await TokenStorage.hasPinCode();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => hasPin
            ? const MainScreen()
            : const PinCodeSettingsScreen(
                showHeader: false,
                isMandatorySetup: true,
              ),
      ),
      (route) => false,
    );
  }

  static String extractErrorMessage(
    Object e, {
    required String fallbackMessage,
  }) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data != null) {
        if (data is Map) {
          final errors = data['errors'];
          String? firstListError;
          if (errors is List && errors.isNotEmpty) {
            firstListError = errors.first?.toString();
          }
          return data['errorMessage']?.toString() ??
              data['message']?.toString() ??
              data['title']?.toString() ??
              firstListError ??
              fallbackMessage;
        }
        if (data is String && data.trim().isNotEmpty) {
          return data.trim();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return tr('auth_network_error');
      }
    } else if (e is Exception) {
      return e.toString().replaceFirst('Exception: ', '');
    }
    return fallbackMessage;
  }
}
