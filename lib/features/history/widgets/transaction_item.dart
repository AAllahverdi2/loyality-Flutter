import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/features/history/models/transaction.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({
    required this.item,
    this.onTap,
    super.key,
  });

  final Transaction item;
  final ValueChanged<String>? onTap;

  // Exact 1-to-1 Ionicons SVGs
  static const String _arrowDownSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="none" stroke="#059669" stroke-linecap="round" stroke-linejoin="round" stroke-width="48" d="M112 268l144 144 144-144M256 392V100"/>
</svg>
''';

  static const String _arrowUpSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path fill="none" stroke="#DC2626" stroke-linecap="round" stroke-linejoin="round" stroke-width="48" d="M112 244l144-144 144 144M256 120v292"/>
</svg>
''';

  static const String _pricetagSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M435.25 48h-122.9a14.44 14.44 0 00-10.2 4.24L56.46 297.93a47.27 47.27 0 000 66.86L147.2 455.53a47.27 47.27 0 0066.86 0l245.69-245.69A14.44 14.44 0 00464 199.64V76.75A28.75 28.75 0 00435.25 48zM368 176a32 32 0 1132-32 32 32 0 01-32 32z" fill="#4F46E5"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final (String svg, Color iconBg, Color amountColor) = switch (item.type) {
      TransactionType.earn => (
          _arrowDownSvg,
          isDark
              ? const Color(0xFF059669).withValues(alpha: 0.15)
              : const Color(0xFFECFDF5),
          const Color(0xFF059669),
        ),
      TransactionType.spend => (
          _arrowUpSvg,
          isDark
              ? const Color(0xFFDC2626).withValues(alpha: 0.15)
              : const Color(0xFFFEF2F2),
          const Color(0xFFDC2626),
        ),
      TransactionType.discount => (
          _pricetagSvg,
          isDark
              ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
              : const Color(0xFFEEF2FF),
          const Color(0xFF4F46E5),
        ),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap != null ? () => onTap!(item.id) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 44x44 Icon Box
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.string(
                    svg,
                    width: 20,
                    height: 20,
                  ),
                ),

                // Text Container
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.subtitle} • ${item.date}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount & Bonus Column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Net olan HƏMİŞƏ YUXARIDA
                    Text(
                      item.amount,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: amountColor,
                      ),
                    ),
                    // Əgər bonusdan ödəniş olunubsa (spentBonus > 0), aşağıda bonusdan nə qədər ödənilib yazılır
                    if (item.spentBonus != null && item.spentBonus! > 0) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626)
                              .withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${item.spentBonus!.toStringAsFixed(2)} bonus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF87171)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                    // Əgər bonus qazanılıbsa (earnedBonus > 0)
                    if (item.earnedBonus != null && item.earnedBonus! > 0) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669)
                              .withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${item.earnedBonus!.toStringAsFixed(2)} bonus',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
