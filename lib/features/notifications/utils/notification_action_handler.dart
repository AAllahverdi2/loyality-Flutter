import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/routes/smooth_page_route.dart';
import 'package:loyallig_flutter/features/chat/chat_topics_screen.dart';
import 'package:loyallig_flutter/features/discounts/discounts_screen.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';

class NotificationActionHandler {
  NotificationActionHandler._();

  static String? actionLabel(AppNotification notification) {
    return switch (notification.action?.toLowerCase()) {
      'open_wallet' => tr('notifications_action_open_wallet'),
      'open_promo' => tr('notifications_action_open_promo'),
      'open_ticket' => tr('notifications_action_open_ticket'),
      _ => null,
    };
  }

  static bool canHandle(AppNotification notification) =>
      actionLabel(notification) != null;

  static Future<void> execute(
    BuildContext context,
    AppNotification notification,
  ) async {
    final action = notification.action?.toLowerCase();
    if (action == null) return;

    switch (action) {
      case 'open_wallet':
        MainScreen.navigateToTab(context, 1);
      case 'open_promo':
        await Navigator.of(context).push(
          SmoothPageRoute<void>(builder: (_) => const DiscountsScreen()),
        );
      case 'open_ticket':
        await Navigator.of(context).push(
          SmoothPageRoute<void>(builder: (_) => const ChatTopicsScreen()),
        );
    }
  }
}
