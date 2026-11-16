import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/services/file_service.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_message_bubble.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_typing_indicator.dart';

class ChatMessagesView extends StatelessWidget {
  final ScrollController scrollController;
  final List<SupportChatMessage> messages;
  final bool isLoadingHistory;
  final bool isOperatorTyping;
  final FileService fileService;

  const ChatMessagesView({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isLoadingHistory,
    required this.isOperatorTyping,
    required this.fileService,
  });

  bool _isSameDay(DateTime? a, DateTime? b) {
    final la = (a ?? DateTime.now()).toLocal();
    final lb = (b ?? DateTime.now()).toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  String _formatDateLabel(DateTime? date) {
    final local = (date ?? DateTime.now()).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(local.year, local.month, local.day);

    if (target == today) {
      return tr('chat_today');
    }
    if (target == yesterday) {
      return tr('chat_yesterday');
    }
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }

  Widget _buildDateChip({
    required String label,
    required Color cardBg,
    required Color secondaryTextColor,
    double topMargin = 0,
  }) {
    return Center(
      child: Container(
        margin: EdgeInsets.only(top: topMargin, bottom: 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryTextColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingHistory && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    if (messages.isEmpty) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _buildDateChip(
            label: tr('chat_today'),
            cardBg: cardBg,
            secondaryTextColor: secondaryTextColor,
          ),
          if (isOperatorTyping) const ChatTypingIndicator(),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length + (isOperatorTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Operator yazır animasiyası
        if (isOperatorTyping && index == messages.length) {
          return const ChatTypingIndicator();
        }

        final msg = messages[index];
        final showDateHeader =
            index == 0 ||
            !_isSameDay(messages[index - 1].createdDate, msg.createdDate);

        final bubble = ChatMessageBubble(
          message: msg,
          fileService: fileService,
        );

        if (!showDateHeader) {
          return bubble;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDateChip(
              label: _formatDateLabel(msg.createdDate),
              cardBg: cardBg,
              secondaryTextColor: secondaryTextColor,
              topMargin: index == 0 ? 0 : 6,
            ),
            bubble,
          ],
        );
      },
    );
  }
}

