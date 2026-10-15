import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class ProfileItem extends StatelessWidget {
  const ProfileItem({
    required this.icon,
    required this.title,
    this.value,
    this.showBadge = false,
    this.isSwitch = false,
    this.switchValue = false,
    this.onSwitchChange,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final bool showBadge;
  final bool isSwitch;
  final bool switchValue;
  final ValueChanged<bool>? onSwitchChange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return InkWell(
      onTap: isSwitch ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Left: Icon Box + Title
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: textColor,
              ),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),

            // Right: Value / Badge / Switch / Chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (value != null) ...[
                  Text(
                    value!,
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (showBadge) ...[
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (isSwitch)
                  Switch(
                    value: switchValue,
                    activeTrackColor: AppColors.base,
                    onChanged: onSwitchChange,
                  )
                else if (value == null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: secondaryTextColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
