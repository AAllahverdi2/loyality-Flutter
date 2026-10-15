import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.label,
    required this.flag,
  });

  final String code;
  final String label;
  final String flag;
}

const List<LanguageOption> kLanguages = [
  LanguageOption(code: 'az', label: 'Azərbaycan', flag: '🇦🇿'),
  LanguageOption(code: 'en', label: 'English', flag: '🇬🇧'),
  LanguageOption(code: 'ru', label: 'Русский', flag: '🇷🇺'),
];

class LanguageBottomSheet extends StatelessWidget {
  const LanguageBottomSheet({
    this.currentLanguage,
    required this.onSelect,
    super.key,
  });

  final String? currentLanguage;
  final ValueChanged<String> onSelect;

  static Future<void> show(
    BuildContext context, {
    String? currentLanguage,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageBottomSheet(
        currentLanguage: currentLanguage,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, activeLangCode, _) {
        return Container(
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24 + (bottomInset > 0 ? bottomInset : 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr('profile_language'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language options
              ...kLanguages.map((lang) {
                final isSelected = lang.code == activeLangCode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.base.withValues(alpha: 0.1)
                        : (isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.base : borderColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      lang.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.base,
                            size: 22,
                          )
                        : null,
                    onTap: () async {
                      await AppLocalizations.changeLanguage(lang.code);
                      onSelect(lang.label);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
