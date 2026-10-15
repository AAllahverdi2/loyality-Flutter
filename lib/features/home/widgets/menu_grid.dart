import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class MenuGrid extends StatelessWidget {
  const MenuGrid({
    this.onDiscountsTap,
    this.onHistoryTap,
    super.key,
  });

  final VoidCallback? onDiscountsTap;
  final VoidCallback? onHistoryTap;

  // Exact 1-to-1 Ionicons "pricetags" SVG from @expo/vector-icons
  static const String _pricetagsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M448 183.8v-123A44.66 44.66 0 00403.29 16H280.36a30.62 30.62 0 00-21.51 8.89L13.09 270.58a44.86 44.86 0 000 63.34l117 117a44.84 44.84 0 0063.33 0L439.11 205.31A30.6 30.6 0 00448 183.8ZM352 144a32 32 0 1132-32 32 32 0 01-32 32Z" fill="#EA580C"/>
  <path d="M496 64a16 16 0 00-16 16v127.37L218.69 468.69a16 16 0 1022.62 22.62l262-262A29.84 29.84 0 00512 208V80a16 16 0 00-16-16Z" fill="#EA580C"/>
</svg>
''';

  // Exact 1-to-1 Ionicons "time" SVG from @expo/vector-icons
  static const String _timeSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M256 48C141.13 48 48 141.13 48 256s93.13 208 208 208 208-93.13 208-208S370.87 48 256 48Zm96 240H256a16 16 0 01-16-16V128a16 16 0 0132 0v128h80a16 16 0 010 32Z" fill="#2563EB"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final subtitleColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.6)
        : AppColors.secondaryText;

    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 32,
      ),
      child: Row(
        children: [
          // Kutu 1 - Endirimlər
          Expanded(
            child: _MenuGridCard(
              backgroundColor: cardBg,
              iconCircleColor: isDark
                  ? const Color(0xFFEA580C).withValues(alpha: 0.2)
                  : const Color(0xFFFFF7ED),
              svgString: _pricetagsSvg,
              title: tr('home_discounts'),
              subtitle: tr('home_actual_offers'),
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: onDiscountsTap,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 16),

          // Kutu 2 - Son istifadələr → Tarixçə
          Expanded(
            child: _MenuGridCard(
              backgroundColor: cardBg,
              iconCircleColor: isDark
                  ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                  : const Color(0xFFEFF6FF),
              svgString: _timeSvg,
              title: tr('home_recent_activities'),
              subtitle: tr('home_history'),
              textColor: textColor,
              subtitleColor: subtitleColor,
              onTap: onHistoryTap,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGridCard extends StatelessWidget {
  const _MenuGridCard({
    required this.backgroundColor,
    required this.iconCircleColor,
    required this.svgString,
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
    required this.isDark,
  });

  final Color backgroundColor;
  final Color iconCircleColor;
  final String svgString;
  final String title;
  final String subtitle;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback? onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // menuIconCircle: 48x48, borderRadius: 24
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: iconCircleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgPicture.string(
                      svgString,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),

                // menuGridTitle: fontSize: 15, fontWeight: '700'
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),

                // menuGridSubtitle: fontSize: 12, fontWeight: '500'
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
