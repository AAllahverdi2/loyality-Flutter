import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/routes/smooth_page_route.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';
import 'package:loyallig_flutter/features/notifications/notifications_screen.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/features/notifications/services/push_notification_service.dart';
import 'package:loyallig_flutter/main.dart';

class InAppNotificationOverlay extends StatefulWidget {
  const InAppNotificationOverlay({super.key});

  @override
  State<InAppNotificationOverlay> createState() =>
      _InAppNotificationOverlayState();
}

class _InAppNotificationOverlayState extends State<InAppNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  StreamSubscription<AppNotification>? _sub;
  Timer? _dismissTimer;
  AppNotification? _activeNotification;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _sub = NotificationsStore.instance.liveToastStream.listen(_showToast);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _showToast(AppNotification notification) {
    if (!mounted) return;
    _dismissTimer?.cancel();
    unawaited(PushNotificationService.instance.playInAppNotificationSound());
    setState(() {
      _activeNotification = notification;
    });
    _animController.forward(from: 0);
    _dismissTimer = Timer(const Duration(seconds: 4), _hideToast);
  }

  Future<void> _hideToast() async {
    _dismissTimer?.cancel();
    if (!mounted || _activeNotification == null) return;
    await _animController.reverse();
    if (mounted) {
      setState(() {
        _activeNotification = null;
      });
    }
  }

  void _handleTap() {
    final item = _activeNotification;
    if (item == null) return;
    unawaited(_hideToast());
    navigatorKey.currentState?.push(
      SmoothPageRoute<void>(
        builder: (_) => NotificationsScreen(initialNotificationId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notification = _activeNotification;
    if (notification == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E22) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Dismissible(
                key: ValueKey('toast_${notification.id}_${notification.createdAt}'),
                direction: DismissDirection.up,
                onDismissed: (_) {
                  _dismissTimer?.cancel();
                  if (mounted) {
                    setState(() => _activeNotification = null);
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _handleTap,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.45 : 0.14,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.base.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notification.isPersonal
                                  ? Icons.notifications_active_rounded
                                  : Icons.campaign_rounded,
                              color: AppColors.base,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.base.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tr('notifications_new_badge'),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.base,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (notification.body.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    notification.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.3,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _hideToast,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
