import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocalizations {
  AppLocalizations._();

  static const String _storageKey = 'app_language_code';
  static const String defaultLanguage = 'az';

  /// Mövcud aktiv dil kodu ('az', 'en', 'ru')
  static final ValueNotifier<String> languageNotifier =
      ValueNotifier<String>(defaultLanguage);

  /// Yadda saxlanmış tərcümələr: {'az': {...}, 'en': {...}, 'ru': {...}}
  static final Map<String, Map<String, String>> _translations = {};

  static const Map<String, String> languageLabels = {
    'az': 'Azərbaycan',
    'en': 'English',
    'ru': 'Русский',
  };

  static String get currentLanguageCode => languageNotifier.value;

  static String get currentLanguageLabel =>
      languageLabels[currentLanguageCode] ?? 'Azərbaycan';

  /// Proqram işə düşəndə çağırılır (main.dart-da)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_storageKey);
      if (savedCode != null && languageLabels.containsKey(savedCode)) {
        languageNotifier.value = savedCode;
      }
    } catch (_) {}

    // Bütün 3 dil üçün JSON fayllarını yükləyirik
    await loadAllLanguages();
  }

  /// JSON fayllarını assets/lang/ qovluğundan oxuyur
  static Future<void> loadAllLanguages() async {
    for (final code in languageLabels.keys) {
      await _loadLanguage(code);
    }
  }

  static Future<void> _loadLanguage(String code) async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/lang/$code.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _translations[code] = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      debugPrint('[$code.json] yüklənərkən xəta: $e');
    }
  }

  /// Dili dəyişmək üçün metod ('az', 'en', 'ru' və ya 'Azərbaycan', 'English', 'Русский' qəbul edir)
  static Future<void> changeLanguage(String codeOrLabel) async {
    String code = codeOrLabel.toLowerCase().trim();

    // Əgər etiket (label) ötürülübsə, koda çeviririk
    for (final entry in languageLabels.entries) {
      if (entry.value.toLowerCase() == code || entry.key == code) {
        code = entry.key;
        break;
      }
    }

    if (!languageLabels.containsKey(code)) {
      code = defaultLanguage;
    }

    if (!_translations.containsKey(code) || _translations[code]!.isEmpty) {
      await _loadLanguage(code);
    }

    languageNotifier.value = code;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, code);
    } catch (_) {}
  }

  /// Mətni cari dilə uyğun gətirir
  static String tr(String key, {Map<String, String>? params}) {
    final currentCode = languageNotifier.value;
    String? text = _translations[currentCode]?[key];

    // Əgər cari dildə yoxdursa, 'az' dilindən götürürük (fallback)
    text ??= _translations[defaultLanguage]?[key];

    // Yenə də tapılmadısa key-in özünü qaytarırıq
    text ??= key;

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        text = text!.replaceAll('{$paramKey}', paramValue);
      });
    }

    return text!;
  }
}

/// Global `tr(key)` funksiyası
String tr(String key, [Map<String, String>? params]) =>
    AppLocalizations.tr(key, params: params);

/// `context.tr(key)` üçün extension
extension BuildContextLocalizationExtension on BuildContext {
  String tr(String key, [Map<String, String>? params]) =>
      AppLocalizations.tr(key, params: params);
}
