import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

import 'package:loyallig_flutter/core/constants/app_colors.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({
    this.monthlyEarned,
    this.monthlySpent,
    this.onFilterTap,
    this.hasActiveFilters = false,
    super.key,
  });

  final double? monthlyEarned;
  final double? monthlySpent;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  // Exact 1-to-1 Ionicons "arrow-down" SVG
  static const String _arrowDownSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="none" stroke="#059669" stroke-linecap="round" stroke-linejoin="round" stroke-width="48" d="M112 268l144 144 144-144M256 392V100"/>
</svg>
''';

  // Exact 1-to-1 Ionicons "arrow-up" SVG
  static const String _arrowUpSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="none" stroke="#DC2626" stroke-linecap="round" stroke-linejoin="round" stroke-width="48" d="M112 244l144-144 144 144M256 120v292"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    final downIconBg = isDark
        ? const Color(0xFF059669).withValues(alpha: 0.15)
        : const Color(0xFFECFDF5);
    final upIconBg = isDark
        ? const Color(0xFFDC2626).withValues(alpha: 0.15)
        : const Color(0xFFFEF2F2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title: "Tarixçə" + Filter Button
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('history_title'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (onFilterTap != null)
                InkWell(
                  onTap: onFilterTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.base.withValues(alpha: 0.15)
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasActiveFilters ? AppColors.base : borderColor,
                        width: hasActiveFilters ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.25 : 0.03),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: hasActiveFilters ? AppColors.base : textColor,
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            top: 9,
                            right: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.base,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Stats Container
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Sol Tərəf (Qazanc)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: downIconBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.string(
                        _arrowDownSvg,
                        width: 16,
                        height: 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('history_earned_month'),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthlyEarned != null
                              ? '+${monthlyEarned!.toStringAsFixed(2)} ₼'
                              : '+0.00 ₼',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Orta Şaquli Xətt
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: borderColor,
              ),

              // Sağ Tərəf (Xərc)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: upIconBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.string(
                        _arrowUpSvg,
                        width: 16,
                        height: 16,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('history_spent_month'),
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthlySpent != null
                              ? '-${monthlySpent!.abs().toStringAsFixed(2)} ₼'
                              : '0.00 ₼',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Section header: "SON ƏMƏLİYYATLAR"
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            tr('history_recent_transactions'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
