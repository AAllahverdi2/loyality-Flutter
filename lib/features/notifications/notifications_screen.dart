import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/features/notifications/utils/notification_action_handler.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    this.initialNotificationId,
    super.key,
  });

  final String? initialNotificationId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationsStore _store = NotificationsStore.instance;
  final ScrollController _scrollController = ScrollController();
  bool _openedInitialDetail = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    NetworkMonitor.instance.reconnectNotifier.addListener(_onReconnected);
    unawaited(_initLoad());
  }

  Future<void> _initLoad() async {
    await _store.loadInitial();
    if (!mounted || _openedInitialDetail) return;

    final targetId = widget.initialNotificationId?.trim();
    if (targetId != null && targetId.isNotEmpty) {
      _openedInitialDetail = true;
      final existing = _store.notifications.where(
        (n) => n.id.trim().toLowerCase() == targetId.toLowerCase(),
      );
      final initialItem = existing.isNotEmpty ? existing.first : null;
      if (mounted) {
        await _openDetail(id: targetId, fallback: initialItem);
      }
    }
  }

  void _onReconnected() {
    if (mounted) {
      unawaited(_store.loadInitial(silent: _store.notifications.isNotEmpty));
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      unawaited(_store.loadMore());
    }
  }

  @override
  void dispose() {
    NetworkMonitor.instance.reconnectNotifier.removeListener(_onReconnected);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkAllAsRead() async {
    final didMark = await _store.markAllAsRead();
    if (!mounted || !didMark) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('notifications_mark_all_success')),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openDetail({
    required String id,
    AppNotification? fallback,
  }) async {
    final detailFuture = _store.openNotificationDetail(id);
    if (!mounted) return;

    final resolved = await detailFuture ?? fallback;
    if (!mounted || resolved == null) return;

    await _showNotificationDetailSheet(resolved);
  }

  Future<void> _showNotificationDetailSheet(AppNotification item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final actionLabel = NotificationActionHandler.actionLabel(item);
    final (IconData icon, Color iconColor, Color iconBg) = item.isPersonal
        ? (
            Icons.notifications_active_rounded,
            AppColors.base,
            AppColors.base.withValues(alpha: 0.12),
          )
        : (
            Icons.campaign_rounded,
            const Color(0xFFF97316),
            const Color(0xFFF97316).withValues(alpha: 0.12),
          );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            14,
            24,
            24 + (bottomInset > 0 ? bottomInset : 8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: secondaryTextColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 22, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ),
                        if (item.formattedFullDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.formattedFullDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.3,
                ),
              ),
              if (item.body.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  item.body,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: secondaryTextColor,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (actionLabel != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      unawaited(NotificationActionHandler.execute(context, item));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.base,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    tr('common_close'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final iconBoxBg =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final headerBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final notifications = _store.notifications;
              final hasAnyUnread =
                  _store.hasUnread || notifications.any((n) => !n.isRead);

              return Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: headerBorder, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 30,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          tr('notifications_title'),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Tooltip(
                          message: tr('notifications_mark_all_read'),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: hasAnyUnread ? _handleMarkAllAsRead : null,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.done_all_rounded,
                                size: 24,
                                color: hasAnyUnread
                                    ? AppColors.base
                                    : secondaryTextColor.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Expanded(
                    child: _buildBody(
                      notifications: notifications,
                      cardBg: cardBg,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                      iconBoxBg: iconBoxBg,
                      isDark: isDark,
                      bottomInset: bottomInset,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody({
    required List<AppNotification> notifications,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required Color iconBoxBg,
    required bool isDark,
    required double bottomInset,
  }) {
    if (_store.isLoading && notifications.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Skeleton(width: 44, height: 44, isCircle: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Skeleton(
                            height: 15,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Skeleton(
                          width: 48,
                          height: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Skeleton(
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    Skeleton(
                      width: 180,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_store.errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_paused_outlined,
                size: 48,
                color: secondaryTextColor,
              ),
              const SizedBox(height: 12),
              Text(
                _store.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _store.loadInitial(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.base,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(tr('common_retry')),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _store.loadInitial(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.65,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr('notifications_empty'),
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _store.loadInitial(silent: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          40 + (bottomInset > 0 ? bottomInset : 16),
        ),
        itemCount: notifications.length + (_store.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= notifications.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final item = notifications[index];
          return _NotificationCard(
            key: ValueKey(item.id),
            item: item,
            cardBg: cardBg,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            borderColor: borderColor,
            iconBoxBg: iconBoxBg,
            isDark: isDark,
            onTap: () => _openDetail(id: item.id, fallback: item),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.cardBg,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.iconBoxBg,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  final AppNotification item;
  final Color cardBg;
  final Color textColor;
  final Color secondaryTextColor;
  final Color borderColor;
  final Color iconBoxBg;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color iconColor) = item.isPersonal
        ? (Icons.notifications_active_rounded, AppColors.base)
        : (Icons.campaign_rounded, const Color(0xFFF97316));

    final itemBg = item.isRead
        ? cardBg
        : (isDark ? const Color(0xFF1A1B20) : const Color(0xFFF9FAFB));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isRead
              ? borderColor
              : AppColors.base.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0 : (item.isRead ? 0.02 : 0.04),
            ),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box + unread indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.isRead
                            ? iconBoxBg
                            : iconColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(icon, size: 22, color: iconColor),
                    ),
                    if (!item.isRead)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                            border: Border.all(color: cardBg, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                                color: textColor,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                          if (item.formattedTime.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              item.formattedTime,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (item.body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.38,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
