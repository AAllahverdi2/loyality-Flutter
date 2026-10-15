import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({
    this.onGoogleTap,
    this.onAppleTap,
    this.isGoogleLoading = false,
    this.dividerText,
    super.key,
  });

  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final bool isGoogleLoading;
  final String? dividerText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final dividerColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final text = dividerText ?? tr('auth_or_login');

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                semanticLabel: 'Google ilə daxil ol',
                onTap: onGoogleTap,
                isLoading: isGoogleLoading,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/google-g.svg',
                      width: 22,
                      height: 22,
                    ),
                    if (isAndroid) ...[
                      const SizedBox(width: 10),
                      Text(
                        'Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!isAndroid) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _SocialButton(
                  semanticLabel: 'Apple ilə daxil ol',
                  onTap: onAppleTap,
                  child: Icon(
                    Icons.apple,
                    size: 26,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.semanticLabel,
    required this.child,
    this.onTap,
    this.isLoading = false,
  });

  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171717) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF303030) : const Color(0xFFE5E7EB);

    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading ? null : onTap,
            child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.base,
                        ),
                      )
                    : child,
            ),
          ),
        ),
      ),
    );
  }
}
