import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Skeleton
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // headerLeft
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(
                          width: 180,
                          height: 20,
                          borderRadius: BorderRadius.circular(6),
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Skeleton(
                          width: 220,
                          height: 14,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // headerRight (2 circular buttons)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Skeleton(width: 44, height: 44, isCircle: true),
                      SizedBox(width: 12),
                      Skeleton(width: 44, height: 44, isCircle: true),
                    ],
                  ),
                ],
              ),
            ),

            // Premium Card Skeleton
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Skeleton(
                width: double.infinity,
                height: 260,
                borderRadius: BorderRadius.circular(24),
              ),
            ),

            // Slider Skeleton
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Column(
                children: [
                  Skeleton(
                    width: double.infinity,
                    height: 195,
                    borderRadius: BorderRadius.circular(24),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Skeleton(width: 8, height: 8, isCircle: true),
                      SizedBox(width: 6),
                      Skeleton(width: 8, height: 8, isCircle: true),
                      SizedBox(width: 6),
                      Skeleton(width: 8, height: 8, isCircle: true),
                    ],
                  ),
                ],
              ),
            ),

            // Menu Grid Skeleton
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Skeleton(
                      height: 100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Skeleton(
                      height: 100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),

            // Partners Header Skeleton
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton(
                    width: 120,
                    height: 20,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  Skeleton(
                    width: 80,
                    height: 20,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),

            // Partners Horizontal List Skeleton
            SizedBox(
              height: 85,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Skeleton(
                    width: 140,
                    height: 85,
                    borderRadius: BorderRadius.circular(20),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
