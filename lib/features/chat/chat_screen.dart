import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/chat/models/support_topic.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    this.isRead = false,
  });

  final String id;
  final String text;
  final String sender; // 'user' or 'agent'
  final String time;
  final bool isRead;

  bool get isUser => sender == 'user';
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.topic,
  });

  final SupportTopic? topic;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final topicName = widget.topic?.name;
    final greetingText = topicName != null && topicName.isNotEmpty
        ? 'Salam! "$topicName" mövzusu üzrə Azera Canlı Dəstək xidmətinə xoş gəlmisiniz. Zəhmət olmasa sualınızı və ya müraciətinizi qeyd edin.'
        : 'Salam! Azera Canlı Dəstək xidmətinə xoş gəlmisiniz. Sizə necə kömək edə bilərəm?';

    _messages = [
      ChatMessage(
        id: '1',
        text: greetingText,
        sender: 'agent',
        time: timeStr,
      ),
    ];
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          sender: 'user',
          time: '$hour:$minute',
          isRead: false,
        ),
      );
    });

    _textController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF141414) : const Color(0xFFFFFFFF);
    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Çat Header
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol hissə: Geri düyməsi + Avatar + Agent məlumatları
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 8),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: textColor,
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: backgroundColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Azera Dəstək',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Onlayn',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Zəng düyməsi
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1F1F1F)
                          : const Color(0xFFF9FAFB),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          // Zəng funksiyası
                        },
                        child: Icon(
                          Icons.call_outlined,
                          size: 22,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Seçilmiş Mövzu Paneli (Əgər mövzu seçilibsə)
            if (widget.topic != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.base.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.topic!.iconData,
                        size: 16,
                        color: AppColors.base,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Mövzu: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.topic!.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (widget.topic!.description != null &&
                              widget.topic!.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.topic!.description!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: secondaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.topic!.priorityName != null &&
                        widget.topic!.priorityName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: widget.topic!.priorityColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.topic!.priorityName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.topic!.priorityColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Çat Məzmunu (Mesajlar)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  // Tarix ayırıcısı ("Bu gün")
                  if (index == 0) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Bu gün',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    );
                  }

                  final msg = _messages[index - 1];
                  final isUser = msg.isUser;
                  final maxBubbleWidth =
                      MediaQuery.sizeOf(context).width * 0.78;

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.base
                            : (isDark
                                ? const Color(0xFF1F2937)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isUser
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: isUser ? Colors.white : textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                msg.time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isUser
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : secondaryTextColor,
                                ),
                              ),
                              if (isUser) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 14,
                                  color: msg.isRead
                                      ? const Color(0xFF60A5FA)
                                      : Colors.white.withValues(alpha: 0.75),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Mesaj Yazma Paneli
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Qoşma (Attach) düyməsi
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded, size: 28),
                        color: secondaryTextColor,
                        onPressed: () {
                          // Şəkil və ya sənəd əlavə etmək
                        },
                      ),
                    ),

                    // Giriş sahəsi
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F2937)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                          ),
                          cursorColor: AppColors.base,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Mesajınızı yazın...',
                            hintStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),

                    // Göndər düyməsi
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _textController,
                      builder: (context, value, _) {
                        final canSend = value.text.trim().isNotEmpty;
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: canSend
                                ? AppColors.base
                                : (isDark
                                    ? const Color(0xFF374151)
                                    : const Color(0xFFE5E7EB)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: canSend ? _sendMessage : null,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: canSend
                                        ? Colors.white
                                        : secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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
