import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class ThemeOption {
  const ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.description,
  });

  final String mode; // 'system' | 'light' | 'dark'
  final String label;
  final IconData icon;
  final String description;
}

class ThemeBottomSheet extends StatelessWidget {
  const ThemeBottomSheet({
    required this.currentMode,
    required this.onSelect,
    super.key,
  });

  final String currentMode;
  final ValueChanged<String> onSelect;

  static Future<void> show(
    BuildContext context, {
    required String currentMode,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ThemeBottomSheet(
        currentMode: currentMode,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeOptions = [
      ThemeOption(
        mode: 'system',
        label: tr('profile_theme_system'),
        icon: Icons.phone_android_rounded,
        description: tr('theme_system_desc'),
      ),
      ThemeOption(
        mode: 'light',
        label: tr('profile_theme_light'),
        icon: Icons.wb_sunny_outlined,
        description: tr('theme_light_desc'),
      ),
      ThemeOption(
        mode: 'dark',
        label: tr('profile_theme_dark'),
        icon: Icons.nightlight_round_outlined,
        description: tr('theme_dark_desc'),
      ),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final handleColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final borderColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFF3F4F6);
    final inputBg =
        isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6);
    const tintColor = Color(0xFFC91C1C);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        20 + (bottomInset > 0 ? bottomInset : 0),
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
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            tr('profile_theme'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 24),

          // Options List
          ...themeOptions.map((option) {
            final isSelected = option.mode == currentMode;

            final itemBg = isSelected
                ? (isDark
                    ? tintColor.withValues(alpha: 0.15)
                    : const Color(0xFFFEF2F2))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF9FAFB));

            final itemBorder = isSelected ? tintColor : borderColor;

            final iconBoxBg = isSelected
                ? (isDark
                    ? tintColor.withValues(alpha: 0.25)
                    : tintColor.withValues(alpha: 0.1))
                : inputBg;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: itemBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: itemBorder, width: 1),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    onSelect(option.mode);
                    Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Icon Box + Texts
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                color: iconBoxBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                option.icon,
                                size: 20,
                                color: isSelected ? tintColor : textColor,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? tintColor : textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Right: Checkmark if selected
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 24,
                            color: tintColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
