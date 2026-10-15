import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';

class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 20),
            child: Skeleton(
              width: 140,
              height: 34,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),

          // Stats Container skeleton
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
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Skeleton(
                        width: 32,
                        height: 32,
                        isCircle: true,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Skeleton(width: 70, height: 12),
                          SizedBox(height: 4),
                          Skeleton(width: 60, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: borderColor,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Skeleton(
                        width: 32,
                        height: 32,
                        isCircle: true,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Skeleton(width: 70, height: 12),
                          SizedBox(height: 4),
                          Skeleton(width: 60, height: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Section header skeleton
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Skeleton(width: 150, height: 16),
          ),

          // 6 x Transaction skeletons
          ...List.generate(6, (index) => _TransactionSkeletonItem(cardBg: cardBg, isDark: isDark)),
        ],
      ),
    );
  }
}

class _TransactionSkeletonItem extends StatelessWidget {
  const _TransactionSkeletonItem({
    required this.cardBg,
    required this.isDark,
  });

  final Color cardBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const Skeleton(
            width: 44,
            height: 44,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 120, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 180, height: 12),
              ],
            ),
          ),
          const Skeleton(width: 70, height: 16),
        ],
      ),
    );
  }
}
