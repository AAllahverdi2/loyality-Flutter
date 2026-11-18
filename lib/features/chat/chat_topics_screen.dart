import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/routes/smooth_page_route.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/chat/chat_screen.dart';
import 'package:loyallig_flutter/features/chat/models/support_conversation.dart';
import 'package:loyallig_flutter/features/chat/models/support_topic.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_conversations_store.dart';
import 'package:loyallig_flutter/features/chat/services/support_topics_service.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_dialogs.dart';

class ChatTopicsScreen extends StatefulWidget {
  const ChatTopicsScreen({super.key});

  @override
  State<ChatTopicsScreen> createState() => _ChatTopicsScreenState();
}

class _ChatTopicsScreenState extends State<ChatTopicsScreen> {
  final SupportTopicsService _service = SupportTopicsService();
  final SupportConversationsStore _conversationsStore =
      SupportConversationsStore.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<SupportTopic> _topics = [];
  List<SupportConversation> _myConversations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _myConversations = _conversationsStore.conversations;
    _conversationsStore.addListener(_onConversationsStoreUpdated);
    NetworkMonitor.instance.reconnectNotifier.addListener(_onReconnected);
    unawaited(SupportChatHubService.instance.initAndConnect());
    _loadTopics();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    NetworkMonitor.instance.reconnectNotifier.removeListener(_onReconnected);
    _conversationsStore.removeListener(_onConversationsStoreUpdated);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onReconnected() {
    if (mounted) {
      unawaited(SupportChatHubService.instance.initAndConnect());
      _loadTopics(silent: _topics.isNotEmpty);
    }
  }

  void _onConversationsStoreUpdated() {
    if (!mounted) return;
    setState(() {
      _myConversations = _conversationsStore.conversations;
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadTopics({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.getActiveTopics(),
        _conversationsStore
            .refreshConversations(silent: true)
            .catchError((_) => _conversationsStore.conversations),
      ]);

      if (!mounted) return;
      setState(() {
        _topics = results[0] as List<SupportTopic>;
        _myConversations = _conversationsStore.conversations;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _errorMessage = SupportChatService.extractFriendlyErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  List<SupportTopic> get _filteredTopics {
    if (_searchQuery.isEmpty) return _topics;
    return _topics.where((t) {
      final matchName = t.name.toLowerCase().contains(_searchQuery);
      final matchDesc =
          t.description?.toLowerCase().contains(_searchQuery) ?? false;
      return matchName || matchDesc;
    }).toList();
  }

  List<SupportConversation> get _activeConversations {
    return _myConversations.where((c) => c.isOpen).toList();
  }

  Future<void> _onTopicSelected(SupportTopic topic) async {
    final activeList = _activeConversations;
    if (activeList.isNotEmpty) {
      final openActive = await ChatDialogs.showActiveConversationWarning(
        context,
      );
      if (openActive && mounted && _activeConversations.isNotEmpty) {
        _onConversationSelected(_activeConversations.first);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context)
        .push(
          SmoothPageRoute<void>(
            builder: (_) => ChatScreen(topic: topic),
          ),
        )
        .then((_) => _loadTopics(silent: true));
  }

  void _onConversationSelected(SupportConversation conv) {
    // Çata daxil olan kimi lokal state-də unreadMessagesCount dərhal 0 edilir
    if (conv.unreadMessagesCount > 0) {
      _conversationsStore.markConversationRead(conv.id);
    }

    final updatedConv = conv.unreadMessagesCount > 0
        ? conv.copyWith(unreadMessagesCount: 0)
        : conv;

    Navigator.of(context)
        .push(
          SmoothPageRoute<void>(
            builder: (_) => ChatScreen(
              conversationId: updatedConv.id,
              conversation: updatedConv,
            ),
          ),
        )
        .then((_) => _loadTopics(silent: true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);
    final cardBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: textColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('support_topics_title'),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tr('support_operator_online'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTopics,
                color: AppColors.base,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // Hero Information Card
                    _buildHeroCard(
                      context,
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 16),

                    // Search input
                    _buildSearchBar(
                      isDark: isDark,
                      cardBg: cardBg,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                      borderColor: borderColor,
                    ),

                    // Aktiv söhbətlər (əgər varsa)
                    if (!_isLoading && _activeConversations.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildActiveConversationsSection(
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('support_topics_section_title'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (!_isLoading && _topics.isNotEmpty)
                          Text(
                            tr('support_topics_count', {
                              'count': '${_filteredTopics.length}',
                            }),
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Topics list or Loading or Error or Empty
                    if (_isLoading)
                      _buildSkeletonList(borderColor: borderColor)
                    else if (_errorMessage != null)
                      _buildErrorCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      )
                    else if (_filteredTopics.isEmpty)
                      _buildEmptyCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      )
                    else
                      ..._filteredTopics.map(
                        (topic) => _buildTopicCard(
                          topic,
                          isDark: isDark,
                          cardBg: cardBg,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                          borderColor: borderColor,
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

  Widget _buildHeroCard(
    BuildContext context, {
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.base.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.support_agent_rounded,
                color: AppColors.base,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('support_hero_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr('support_topics_subtitle'),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar({
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
        cursorColor: AppColors.base,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          hintText: tr('support_topics_search'),
          hintStyle: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: secondaryTextColor,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: secondaryTextColor,
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  String? _formatConversationTime(DateTime? date) {
    if (date == null) return null;
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(local.year, local.month, local.day);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (target == today) {
      return '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
    }
    if (target == yesterday) {
      return tr('chat_yesterday');
    }
    return '${twoDigits(local.day)}.${twoDigits(local.month)}';
  }

  Widget _buildUnreadBadge(int unreadMessagesCount) {
    if (unreadMessagesCount <= 0) {
      return const SizedBox.shrink();
    }
    final badgeText = unreadMessagesCount > 99
        ? '99+'
        : '$unreadMessagesCount';
    final isMultiChar = badgeText.length > 1;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 21,
        minHeight: 21,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMultiChar ? 6 : 0,
        vertical: 2,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badgeText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          height: 1.1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActiveConversationsSection({
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr('support_active_conversations'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                tr('support_active_count', {
                  'count': '${_activeConversations.length}',
                }),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._activeConversations.map((conv) {
          final hasUnread = conv.unreadMessagesCount > 0;
          final timeLabel = _formatConversationTime(
            conv.lastMessageDate ?? conv.updatedDate ?? conv.createdDate,
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.base.withValues(alpha: hasUnread ? 0.55 : 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.base.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _onConversationSelected(conv),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.base.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.base,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.topicName ??
                                        conv.title ??
                                        tr('support_default_chat_title'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeLabel != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    timeLabel,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: hasUnread
                                          ? const Color(0xFFEF4444)
                                          : secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.lastMessage?.isNotEmpty == true
                                        ? (conv.lastMessage!.trim() ==
                                                  '📷 Şəkil'
                                              ? tr('chat_photo_message')
                                              : conv.lastMessage!)
                                        : tr('support_tap_to_continue'),
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: hasUnread
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: hasUnread
                                          ? textColor
                                          : secondaryTextColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  _buildUnreadBadge(conv.unreadMessagesCount),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopicCard(
    SupportTopic topic, {
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    final hasDesc = topic.description != null && topic.description!.isNotEmpty;
    final priorityLabel = topic.localizedPriorityName;
    final hasPriority = priorityLabel != null && priorityLabel.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTopicSelected(topic),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Topic Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF27272A)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      topic.iconData,
                      size: 22,
                      color: AppColors.base,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              topic.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (hasPriority) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: topic.priorityColor
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                priorityLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: topic.priorityColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasDesc) ...[
                        const SizedBox(height: 4),
                        Text(
                          topic.description!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            color: secondaryTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: secondaryTextColor.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonList({required Color borderColor}) {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Skeleton(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Skeleton(
                      width: 160,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 8),
                    Skeleton(
                      width: 220,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Skeleton(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard({
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFEF4444),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('discounts_error_occurred'),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadTopics,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.base,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              tr('support_topics_retry'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.base.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.search_off_rounded,
                color: AppColors.base,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('support_topics_empty'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? tr('support_topics_empty_search')
                : tr('support_topics_empty_soon'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
