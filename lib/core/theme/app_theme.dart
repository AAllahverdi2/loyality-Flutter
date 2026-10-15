import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

abstract final class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static void setThemeMode(String mode) {
    switch (mode) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  static String get currentModeString {
    switch (themeModeNotifier.value) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final foreground = isDark ? AppColors.darkText : AppColors.text;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.base,
        brightness: brightness,
        primary: AppColors.base,
        surface: background,
        error: AppColors.error,
      ),
      fontFamily: 'Roboto',
      textTheme: ThemeData(brightness: brightness).textTheme
          .apply(bodyColor: foreground, displayColor: foreground),
      dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.darkInputBackground
            : AppColors.inputBackground,
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        border: _inputBorder(isDark),
        enabledBorder: _inputBorder(isDark),
        focusedBorder: _inputBorder(isDark, color: AppColors.base),
        errorBorder: _inputBorder(isDark, color: AppColors.error),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(bool isDark, {Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: color ?? (isDark ? AppColors.darkBorder : AppColors.border),
      ),
    );
  }
}
