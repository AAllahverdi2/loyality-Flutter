import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // 1-to-1 exact Ionicons SVGs from @expo/vector-icons
  static const String _homeFilledSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M261.56 101.28a8 8 0 00-11.06 0L66.4 277.15a8 8 0 00-2.47 5.79L63.9 448a32 32 0 0032 32H192a16 16 0 0016-16V328a8 8 0 018-8h80a8 8 0 018 8l0 136a16 16 0 0016 16h96.06a32 32 0 0032-32l0-165.06a8 8 0 00-2.47-5.79Z"/>
  <path d="M490.91 244.15l-74.8-71.56 0-108.59a16 16 0 00-16-16h-48a16 16 0 00-16 16l0 32L278.19 40.62C272.77 35.14 264.71 32 256 32h0c-8.68 0-16.72 3.14-22.14 8.63L21.16 244.13c-6.22 6-7 15.87-1.34 22.37A16 16 0 0043 267.56L250.5 69.28a8 8 0 0111.06 0L469.08 267.56a16 16 0 0022.59-.44C497.81 260.76 497.3 250.26 490.91 244.15Z"/>
</svg>
''';

  static const String _homeOutlineSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M80 212V448a16 16 0 0016 16h96V328a24 24 0 0124-24h80a24 24 0 0124 24V464h96a16 16 0 0016-16V212" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
  <path d="M480 256L266.89 52c-5-5.28-16.69-5.34-21.78 0L32 256" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
  <path d="M400 179V64h-48v69" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
</svg>
''';

  static const String _timeFilledSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M256 48C141.13 48 48 141.13 48 256s93.13 208 208 208 208-93.13 208-208S370.87 48 256 48Zm96 240H256a16 16 0 01-16-16V128a16 16 0 0132 0v128h80a16 16 0 010 32Z"/>
</svg>
''';

  static const String _timeOutlineSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M256 64C150 64 64 150 64 256s86 192 192 192 192-86 192-192S362 64 256 64Z" fill="none" stroke="currentColor" stroke-miterlimit="10" stroke-width="32"/>
  <path d="M256 128v144h96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
</svg>
''';

  static const String _heartFilledSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M256 448a32 32 0 01-18-5.57c-78.59-53.35-112.62-89.93-131.39-112.8-40-48.75-59.15-98.8-58.61-153C48.63 114.52 98.46 64 159.08 64c44.08 0 74.61 24.83 92.39 45.51a6 6 0 009.06 0C278.31 88.81 308.84 64 352.92 64c60.62 0 110.45 50.52 111.08 112.64.54 54.21-18.63 104.26-58.61 153-18.77 22.87-52.8 59.45-131.39 112.8A32 32 0 01256 448Z"/>
</svg>
''';

  static const String _heartOutlineSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M352.92 80C288 80 256 144 256 144s-32-64-96.92-64C106.32 80 64.54 124.14 64 176.81c-1.1 109.33 86.73 187.08 183 252.42a16 16 0 0018 0c96.26-65.34 184.09-143.09 183-252.42C447.46 124.14 405.68 80 352.92 80Z" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
</svg>
''';

  static const String _personFilledSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M332.64 64.58C313.18 43.57 286 32 256 32c-30.16 0-57.43 11.5-76.8 32.38-19.58 21.11-29.12 49.8-26.88 80.78C156.76 206.28 203.27 256 256 256s99.16-49.71 103.67-110.82C361.94 114.48 352.34 85.85 332.64 64.58Z"/>
  <path d="M432 480H80a31 31 0 01-26.2-11.13c-6.5-7.77-9.12-18.38-7.18-29.11C57.06 392.94 83.4 353.61 124.8 326c36.78-24.51 83.37-38 131.2-38s94.42 13.5 131.2 38c41.4 27.6 67.74 66.93 76.18 113.75 1.94 10.73-.68 21.34-7.18 29.11A31 31 0 01432 480Z"/>
</svg>
''';

  static const String _personOutlineSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M344 144c-3.92 52.87-44 96-88 96s-84.15-43.12-88-96c-4-55 35-96 88-96s92 41 88 96Z" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
  <path d="M256 304c-87 0-175.3 48-191.64 138.6C62.39 453.52 68.57 464 80 464H432c11.44 0 17.62-10.48 15.65-21.4C431.3 352 343 304 256 304Z" fill="none" stroke="currentColor" stroke-miterlimit="10" stroke-width="32"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final activeColor = isDark ? Colors.white : AppColors.text;
    final inactiveColor = isDark
        ? AppColors.darkText.withValues(alpha: 0.5)
        : AppColors.secondaryText;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(
                index: 0,
                filledSvg: _homeFilledSvg,
                outlineSvg: _homeOutlineSvg,
                size: 24,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildTab(
                index: 1,
                filledSvg: _timeFilledSvg,
                outlineSvg: _timeOutlineSvg,
                size: 25,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildTab(
                index: 2,
                filledSvg: _heartFilledSvg,
                outlineSvg: _heartOutlineSvg,
                size: 25,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              _buildTab(
                index: 3,
                filledSvg: _personFilledSvg,
                outlineSvg: _personOutlineSvg,
                size: 24,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String filledSvg,
    required String outlineSvg,
    required double size,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final focused = currentIndex == index;
    final color = focused ? activeColor : inactiveColor;
    final svgString = focused ? filledSvg : outlineSvg;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 50,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              svgString,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            // activeDot: 5x5, radius 2.5, #C91C1C
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: focused ? 1.0 : 0.0,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFFC91C1C),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
