import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

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
            padding: EdgeInsets.only(left: 20, top: 10, bottom: 20),
            child: Skeleton(
              width: 100,
              height: 34,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),

          // User Card skeleton
          Center(
            child: Column(
              children: [
                const Skeleton(
                  width: 100,
                  height: 100,
                  isCircle: true,
                ),
                const SizedBox(height: 12),
                const Skeleton(width: 200, height: 24),
                const SizedBox(height: 8),
                const Skeleton(width: 160, height: 16),
                const SizedBox(height: 12),
                const Skeleton(
                  width: 120,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Section 1 skeleton
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 8),
            child: Skeleton(width: 180, height: 14),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                _SkeletonItem(),
                _SkeletonItem(),
                _SkeletonItem(),
              ],
            ),
          ),

          // Section 2 skeleton
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 8),
            child: Skeleton(width: 80, height: 14),
          ),
          Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: const [
                _SkeletonItem(),
                _SkeletonItem(),
                _SkeletonItem(),
              ],
            ),
          ),

          // Logout button skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Skeleton(
              width: double.infinity,
              height: 56,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Skeleton(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 12),
              Skeleton(width: 140, height: 16),
            ],
          ),
          const Skeleton(
            width: 20,
            height: 20,
            isCircle: true,
          ),
        ],
      ),
    );
  }
}
