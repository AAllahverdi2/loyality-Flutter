import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/notifications/services/notification_permission_service.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';

class NotificationPermissionSheet extends StatefulWidget {
  const NotificationPermissionSheet({super.key});

  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationPermissionSheet(),
    );
  }

  @override
  State<NotificationPermissionSheet> createState() =>
      _NotificationPermissionSheetState();
}

class _NotificationPermissionSheetState
    extends State<NotificationPermissionSheet> {
  bool _loading = false;

  Future<void> _handleAllow() async {
    if (_loading) return;
    setState(() => _loading = true);
    final service = NotificationPermissionService.instance;
    final status = service.hasNativeRuntimeDialog
        ? await service.requestPermission()
        : await service.checkPermissionStatus();
    await service.setPromptedPermission(true);
    if (status == NotificationPermissionStatus.granted ||
        !service.hasNativeRuntimeDialog) {
      await NotificationsStore.instance.toggleNotifications(true);
    } else {
      await NotificationsStore.instance.refreshNotificationPermissionStatus();
    }
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  Future<void> _handleSkip() async {
    await NotificationPermissionService.instance.setPromptedPermission(true);
    await NotificationsStore.instance.toggleNotifications(false);
    await NotificationsStore.instance.refreshNotificationPermissionStatus();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.base.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.base.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.base,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            tr('notifications_prompt_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr('notifications_prompt_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else
            PrimaryButton(
              label: tr('notifications_prompt_allow'),
              onPressed: _handleAllow,
            ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loading ? null : _handleSkip,
            child: Text(
              tr('notifications_prompt_not_now'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
