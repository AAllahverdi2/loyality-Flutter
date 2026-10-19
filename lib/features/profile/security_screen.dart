import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/routes/smooth_page_route.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/profile/biometric_settings_screen.dart';
import 'package:loyallig_flutter/features/profile/change_password_screen.dart';
import 'package:loyallig_flutter/features/profile/pin_code_settings_screen.dart';

class SecurityScreen extends StatelessWidget {
  final int? initialIndex;

  const SecurityScreen({
    super.key,
    this.initialIndex,
  });

  void _navigateToBiometric(BuildContext context) {
    Navigator.of(context).push(
      SmoothPageRoute<void>(
        builder: (_) => const BiometricSettingsScreen(showHeader: true),
      ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    Navigator.of(context).push(
      SmoothPageRoute<void>(
        builder: (_) => const ChangePasswordScreen(showHeader: true),
      ),
    );
  }

  void _navigateToPinCode(BuildContext context) {
    Navigator.of(context).push(
      SmoothPageRoute<void>(
        builder: (_) => const PinCodeSettingsScreen(showHeader: true),
      ),
    );
  }

  Widget _buildSecurityOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.base,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryTextColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: secondaryTextColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final cardBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171717) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF303030)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        color: textColor,
                        size: 26,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        tr('security_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Body: Centered vertically with 3 stacked options
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Visual Icon Badge
                      Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF27272A)
                                : const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.base.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.shield_outlined,
                            size: 44,
                            color: AppColors.base,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          tr('security_title'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          tr('security_header_desc'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Option 1: Biometrik təhlükəsizlik
                      _buildSecurityOptionCard(
                        context: context,
                        icon: Icons.fingerprint_rounded,
                        title: tr('security_tab_biometric'),
                        subtitle: tr('security_biometric_subtitle'),
                        onTap: () => _navigateToBiometric(context),
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),

                      // Option 2: Şifrəni dəyişdir
                      _buildSecurityOptionCard(
                        context: context,
                        icon: Icons.lock_reset_rounded,
                        title: tr('security_tab_change_password'),
                        subtitle: tr('security_change_password_subtitle'),
                        onTap: () => _navigateToChangePassword(context),
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),

                      // Option 3: PIN kod təyin et
                      _buildSecurityOptionCard(
                        context: context,
                        icon: Icons.dialpad_rounded,
                        title: tr('security_tab_set_pin'),
                        subtitle: tr('security_pin_code_subtitle'),
                        onTap: () => _navigateToPinCode(context),
                        isDark: isDark,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
