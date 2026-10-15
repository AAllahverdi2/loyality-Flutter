import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';

class FavoritesSkeleton extends StatelessWidget {
  const FavoritesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title skeleton
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 20),
            child: Skeleton(
              width: 160,
              height: 34,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),

          // Search wrap skeleton
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
            child: const Skeleton(
              width: double.infinity,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),

          // 6 x FavoriteSkeletonCard
          ...List.generate(
            6,
            (index) => _FavoriteSkeletonCard(cardBg: cardBg, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _FavoriteSkeletonCard extends StatelessWidget {
  const _FavoriteSkeletonCard({
    required this.cardBg,
    required this.isDark,
  });

  final Color cardBg;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
            width: 60,
            height: 60,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Skeleton(width: 80, height: 12),
                SizedBox(height: 8),
                Skeleton(width: 160, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 100, height: 14),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: Skeleton(
              width: 20,
              height: 20,
              isCircle: true,
            ),
          ),
        ],
      ),
    );
  }
}
