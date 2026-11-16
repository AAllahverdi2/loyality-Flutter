import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/chat/controllers/chat_controller.dart';
import 'package:loyallig_flutter/features/chat/models/support_conversation.dart';
import 'package:loyallig_flutter/features/chat/models/support_topic.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_closed_banner.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_dialogs.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_header.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_input_bar.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_messages_view.dart';
import 'package:loyallig_flutter/features/chat/widgets/chat_topic_banner.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.conversationId,
    this.topic,
    this.conversation,
  });

  final String? conversationId;
  final SupportTopic? topic;
  final SupportConversation? conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(
      conversationId: widget.conversationId ?? widget.conversation?.id,
      topic: widget.topic,
      conversation: widget.conversation,
    );

    _controller.onShowNotification = (message, {bool isError = false}) {
      _showCompactNotification(message, isError: isError);
    };

    _controller.init();
    _textController.addListener(_handleTextChanged);
  }

  void _showCompactNotification(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF27272A),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        duration: const Duration(milliseconds: 2400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTextChanged() {
    _controller.onTextChanged(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > ChatController.maxMessageLength) {
      _showCompactNotification(
        tr('chat_max_length_error', {
          'max': '${ChatController.maxMessageLength}',
        }),
        isError: true,
      );
      return;
    }
    _textController.clear();
    _controller.sendMessage(text);
  }

  Future<void> _handlePickAttachment() async {
    final source = await ChatDialogs.showAttachmentPicker(context);
    if (source != null) {
      _controller.pickAndSendAttachment(source);
    }
  }

  Future<void> _handleCloseConversation() async {
    final confirmed = await ChatDialogs.showCloseConfirmation(context);
    if (confirmed) {
      _controller.closeConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFFFFFFF);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                children: [
                  // 1. Header
                  ChatHeader(
                    onBack: () => Navigator.of(context).pop(),
                    isOperatorTyping: _controller.isOperatorTyping,
                    connectionState: _controller.connectionState,
                    isClosed: _controller.isClosed,
                    hasConversation:
                        _controller.conversationId != null &&
                        _controller.conversationId!.trim().isNotEmpty,
                    onRefresh: _controller.loadHistory,
                    onClose: _handleCloseConversation,
                  ),

                  // 2. Seçilmiş Mövzu Paneli
                  if (_controller.topicName != null &&
                      _controller.topicName!.isNotEmpty)
                    ChatTopicBanner(
                      topicName: _controller.topicName!,
                      topic: _controller.topic,
                      isClosed: _controller.isClosed,
                    ),

                  // 3. Bağlanmış söhbət xəbərdarlıq paneli
                  if (_controller.isClosed) const ChatClosedBanner(),

                  // 4. Çat Məzmunu (Mesajlar)
                  Expanded(
                    child: ChatMessagesView(
                      scrollController: _controller.scrollController,
                      messages: _controller.messages,
                      isLoadingHistory: _controller.isLoadingHistory,
                      isOperatorTyping: _controller.isOperatorTyping,
                      fileService: _controller.fileService,
                    ),
                  ),

                  // 5. Mesaj Yazma Paneli
                  ChatInputBar(
                    controller: _textController,
                    isClosed: _controller.isClosed,
                    isSending: _controller.isSending,
                    isUploadingAttachment: _controller.isUploadingAttachment,
                    onPickAttachment: _handlePickAttachment,
                    onSend: _handleSendMessage,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
