import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/notifications/models/notification_item.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/features/notifications/utils/notification_action_handler.dart';

enum _NotificationFilter { all, unread, personal, broadcast }

class _NotificationGroup {
  const _NotificationGroup({
    required this.label,
    required this.items,
  });

  final String label;
  final List<AppNotification> items;
}

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
  _NotificationFilter _selectedFilter = _NotificationFilter.all;

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

  List<AppNotification> _applyFilter(List<AppNotification> all) {
    return switch (_selectedFilter) {
      _NotificationFilter.all => all,
      _NotificationFilter.unread => all.where((n) => !n.isRead).toList(),
      _NotificationFilter.personal => all.where((n) => n.isPersonal).toList(),
      _NotificationFilter.broadcast =>
        all.where((n) => n.isBroadcast).toList(),
    };
  }

  List<_NotificationGroup> _groupByDate(List<AppNotification> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<AppNotification>>{};
    final order = <String>[];

    for (final item in items) {
      final label = _dateSectionLabel(item.createdAt?.toLocal(), today);
      if (!groups.containsKey(label)) {
        groups[label] = [];
        order.add(label);
      }
      groups[label]!.add(item);
    }

    return [
      for (final label in order)
        _NotificationGroup(label: label, items: groups[label]!),
    ];
  }

  String _dateSectionLabel(DateTime? dt, DateTime today) {
    if (dt == null) return tr('notifications_earlier');
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = today.difference(itemDay).inDays;
    if (diffDays == 0) return tr('history_today');
    if (diffDays == 1) return tr('history_yesterday');

    final lang = AppLocalizations.currentLanguageCode.toLowerCase();
    const azMonths = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'İyun',
      'İyul',
      'Avqust',
      'Sentyabr',
      'Oktyabr',
      'Noyabr',
      'Dekabr',
    ];
    const enMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const ruMonths = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    final months = lang == 'en'
        ? enMonths
        : (lang == 'ru' ? ruMonths : azMonths);
    final month = months[(dt.month - 1).clamp(0, 11)];
    if (dt.year == today.year) {
      return '${dt.day} $month';
    }
    return '${dt.day} $month ${dt.year}';
  }

  String _formatShortTime(AppNotification item) {
    final dt = item.createdAt?.toLocal();
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _showNotificationDetailSheet(AppNotification item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF141418) : Colors.white;
    final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final closeBtnBg = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);

    final actionLabel = NotificationActionHandler.actionLabel(item);
    final accentColor = item.isPersonal
        ? AppColors.base
        : const Color(0xFFF97316);
    final icon = item.isPersonal
        ? Icons.notifications_active_rounded
        : Icons.campaign_rounded;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.paddingOf(ctx).bottom;
        final maxSheetHeight = MediaQuery.sizeOf(ctx).height * 0.86;
        final imageUrl = item.imageUrl;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(
              22,
              12,
              22,
              22 + (bottomInset > 0 ? bottomInset : 6),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _NotificationIconBadge(
                        icon: icon,
                        accentColor: accentColor,
                        size: 48,
                        iconSize: 22,
                        radius: 15,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.typeLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ],
                            ),
                            if (item.formattedFullDate.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.formattedFullDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: closeBtnBg,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, thickness: 1, color: borderColor),
                  const SizedBox(height: 18),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.body,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                  if (imageUrl != null) ...[
                    const SizedBox(height: 18),
                    _NotificationDetailImage(
                      imageUrl: imageUrl,
                      heroTag: 'notif_img_${item.id}',
                      borderColor: borderColor,
                      isDark: isDark,
                      onTap: () => _openImageFullscreen(
                        ctx,
                        imageUrl: imageUrl,
                        heroTag: 'notif_img_${item.id}',
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (actionLabel != null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          unawaited(
                            NotificationActionHandler.execute(context, item),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.base,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
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
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: closeBtnBg,
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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
            ),
          ),
        );
      },
    );
  }

  void _openImageFullscreen(
    BuildContext context, {
    required String imageUrl,
    required String heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _NotificationFullScreenImage(
          imageUrl: imageUrl,
          heroTag: heroTag,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF09090B) : const Color(0xFFF6F7F9);
    final surfaceBg = isDark ? const Color(0xFF141418) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final controlBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white;

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: _store,
            builder: (context, _) {
              final allNotifications = _store.notifications;
              final unreadCount = _store.unreadCount > 0
                  ? _store.unreadCount
                  : allNotifications.where((n) => !n.isRead).length;
              final hasAnyUnread = unreadCount > 0;
              final filtered = _applyFilter(allNotifications);

              return Column(
                children: [
                  // Modern Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                    child: Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          iconSize: 24,
                          backgroundColor: controlBg,
                          borderColor: borderColor,
                          iconColor: textColor,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                tr('notifications_title'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: textColor,
                                ),
                              ),
                              if (hasAnyUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.base,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Tooltip(
                          message: tr('notifications_mark_all_read'),
                          child: _HeaderIconButton(
                            icon: Icons.done_all_rounded,
                            iconSize: 20,
                            backgroundColor: hasAnyUnread
                                ? AppColors.base.withValues(
                                    alpha: isDark ? 0.18 : 0.10,
                                  )
                                : controlBg,
                            borderColor: hasAnyUnread
                                ? AppColors.base.withValues(alpha: 0.30)
                                : borderColor,
                            iconColor: hasAnyUnread
                                ? AppColors.base
                                : secondaryTextColor.withValues(alpha: 0.45),
                            onTap: hasAnyUnread ? _handleMarkAllAsRead : null,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips
                  if (allNotifications.isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        children: [
                          _FilterChipPill(
                            label: tr('notifications_filter_all'),
                            selected:
                                _selectedFilter == _NotificationFilter.all,
                            isDark: isDark,
                            surfaceBg: surfaceBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryColor: secondaryTextColor,
                            onTap: () => setState(
                              () => _selectedFilter = _NotificationFilter.all,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipPill(
                            label: tr('notifications_filter_unread'),
                            badgeCount: unreadCount,
                            selected:
                                _selectedFilter == _NotificationFilter.unread,
                            isDark: isDark,
                            surfaceBg: surfaceBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryColor: secondaryTextColor,
                            onTap: () => setState(
                              () =>
                                  _selectedFilter = _NotificationFilter.unread,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipPill(
                            label: tr('notifications_type_personal'),
                            selected:
                                _selectedFilter == _NotificationFilter.personal,
                            isDark: isDark,
                            surfaceBg: surfaceBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryColor: secondaryTextColor,
                            onTap: () => setState(
                              () => _selectedFilter =
                                  _NotificationFilter.personal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterChipPill(
                            label: tr('notifications_type_broadcast'),
                            selected: _selectedFilter ==
                                _NotificationFilter.broadcast,
                            isDark: isDark,
                            surfaceBg: surfaceBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryColor: secondaryTextColor,
                            onTap: () => setState(
                              () => _selectedFilter =
                                  _NotificationFilter.broadcast,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Body
                  Expanded(
                    child: _buildBody(
                      allNotifications: allNotifications,
                      filtered: filtered,
                      surfaceBg: surfaceBg,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
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
    required List<AppNotification> allNotifications,
    required List<AppNotification> filtered,
    required Color surfaceBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
    required bool isDark,
    required double bottomInset,
  }) {
    if (_store.isLoading && allNotifications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Skeleton(
              width: 82,
              height: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: List.generate(5, (idx) {
                return Column(
                  children: [
                    if (idx > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 72),
                        child: Divider(height: 1, color: borderColor),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Skeleton(
                            width: 42,
                            height: 42,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Skeleton(
                                        height: 14,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(width: 28),
                                    Skeleton(
                                      width: 38,
                                      height: 11,
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
                                  width: 140,
                                  height: 11,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    }

    if (_store.errorMessage != null && allNotifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.base.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_paused_rounded,
                  size: 32,
                  color: AppColors.base,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _store.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => _store.loadInitial(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.base,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  tr('common_retry'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (allNotifications.isEmpty) {
      return RefreshIndicator(
        color: AppColors.base,
        onRefresh: () => _store.loadInitial(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.62,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 34,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('notifications_empty'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.filter_list_off_rounded,
                  size: 28,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                tr('notifications_filter_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () =>
                    setState(() => _selectedFilter = _NotificationFilter.all),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.base.withValues(alpha: 0.12),
                  foregroundColor: AppColors.base,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr('notifications_show_all'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _groupByDate(filtered);

    return RefreshIndicator(
      color: AppColors.base,
      onRefresh: () => _store.loadInitial(silent: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          18,
          6,
          18,
          36 + (bottomInset > 0 ? bottomInset : 16),
        ),
        itemCount: groups.length + (_store.isLoadingMore ? 1 : 0),
        itemBuilder: (context, groupIndex) {
          if (groupIndex >= groups.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.base,
                  ),
                ),
              ),
            );
          }

          final group = groups[groupIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                  child: Text(
                    group.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 0.8),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19.2),
                    child: Column(
                      children: [
                        for (int i = 0; i < group.items.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 71),
                              child: Divider(
                                height: 1,
                                thickness: 0.8,
                                color: borderColor,
                              ),
                            ),
                          _NotificationRow(
                            key: ValueKey(group.items[i].id),
                            item: group.items[i],
                            shortTime: _formatShortTime(group.items[i]),
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            isDark: isDark,
                            onTap: () => _openDetail(
                              id: group.items[i].id,
                              fallback: group.items[i],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.iconSize,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: 0.8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: iconColor),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.surfaceBg,
    required this.borderColor,
    required this.textColor,
    required this.secondaryColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final Color surfaceBg;
  final Color borderColor;
  final Color textColor;
  final Color secondaryColor;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.base : surfaceBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.base : borderColor,
            width: 0.9,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.base.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : secondaryColor,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.base.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.base,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationIconBadge extends StatelessWidget {
  const _NotificationIconBadge({
    required this.icon,
    required this.accentColor,
    required this.isDark,
    this.size = 42,
    this.iconSize = 20,
    this.radius = 13,
    this.showUnreadDot = false,
  });

  final IconData icon;
  final Color accentColor;
  final bool isDark;
  final double size;
  final double iconSize;
  final double radius;
  final bool showUnreadDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.24 : 0.16),
              width: 0.9,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: iconSize, color: accentColor),
        ),
        if (showUnreadDot)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.base,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF141418) : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.shortTime,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isDark,
    required this.onTap,
    super.key,
  });

  final AppNotification item;
  final String shortTime;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = item.isPersonal
        ? AppColors.base
        : const Color(0xFFF97316);
    final icon = item.isPersonal
        ? Icons.notifications_active_rounded
        : Icons.campaign_rounded;
    final unreadBg = !item.isRead
        ? AppColors.base.withValues(alpha: isDark ? 0.07 : 0.04)
        : Colors.transparent;

    return Material(
      color: unreadBg,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!item.isRead)
                Container(
                  width: 3,
                  color: AppColors.base,
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    item.isRead ? 15 : 12,
                    14,
                    14,
                    14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationIconBadge(
                        icon: icon,
                        accentColor: accentColor,
                        isDark: isDark,
                        showUnreadDot: !item.isRead,
                      ),
                      const SizedBox(width: 13),
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
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                ),
                                if (shortTime.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    shortTime,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor.withValues(
                                        alpha: 0.85,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: secondaryTextColor.withValues(
                                    alpha: 0.45,
                                  ),
                                ),
                              ],
                            ),
                            if (item.body.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.2,
                                  height: 1.4,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.typeLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor.withValues(alpha: 0.9),
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.base.withValues(
                                        alpha: isDark ? 0.22 : 0.12,
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
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _NotificationDetailImage extends StatelessWidget {
  const _NotificationDetailImage({
    required this.imageUrl,
    required this.heroTag,
    required this.borderColor,
    required this.isDark,
    required this.onTap,
  });

  final String imageUrl;
  final String heroTag;
  final Color borderColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholderBg = isDark
        ? const Color(0xFF1F1F24)
        : const Color(0xFFF3F4F6);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: heroTag,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Container(
              decoration: BoxDecoration(
                color: placeholderBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  imageUrl,
                  headers: ApiClient.instance.authHeaders,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame == null && !wasSynchronouslyLoaded) {
                      return child;
                    }
                    return Stack(
                      children: [
                        child,
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Skeleton(
                      width: double.infinity,
                      height: 180,
                      borderRadius: BorderRadius.all(Radius.circular(15)),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    width: double.infinity,
                    height: 120,
                    color: placeholderBg,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 32,
                      color: isDark ? Colors.white38 : Colors.black26,
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

class _NotificationFullScreenImage extends StatelessWidget {
  const _NotificationFullScreenImage({
    required this.imageUrl,
    required this.heroTag,
  });

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: Hero(
                        tag: heroTag,
                        child: Image.network(
                          imageUrl,
                          headers: ApiClient.instance.authHeaders,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white70,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
