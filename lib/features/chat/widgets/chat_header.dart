import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onBack;
  final bool isOperatorTyping;
  final HubConnectionState connectionState;
  final bool isClosed;
  final bool hasConversation;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const ChatHeader({
    super.key,
    required this.onBack,
    required this.isOperatorTyping,
    required this.connectionState,
    required this.isClosed,
    this.hasConversation = true,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFFFFFFF);
    final textColor = isDark
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF111827);
    final borderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFF3F4F6);

    final isConnecting =
        connectionState == HubConnectionState.Connecting ||
        connectionState == HubConnectionState.Reconnecting;

    final statusColor = isClosed
        ? const Color(0xFF9CA3AF)
        : isOperatorTyping
        ? Colors.blue
        : (connectionState == HubConnectionState.Connected
              ? const Color(0xFF10B981)
              : (isConnecting
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444)));

    final statusText = isClosed
        ? tr('chat_status_closed')
        : isOperatorTyping
        ? tr('chat_status_typing')
        : (connectionState == HubConnectionState.Connected
              ? tr('chat_status_online')
              : (isConnecting
                    ? tr('chat_status_connecting')
                    : tr('chat_status_offline')));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol hissə: Geri düyməsi + Avatar + Agent məlumatları
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
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
                      border: Border.all(color: borderColor, width: 1),
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
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: backgroundColor, width: 2),
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
                    tr('chat_header_title'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Sağ hissə: Menyu (yalnız söhbət yaradıldıqdan sonra)
          if (hasConversation)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 22,
                color: textColor,
              ),
              color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              onSelected: (val) {
                if (val == 'close') {
                  onClose();
                } else if (val == 'refresh') {
                  onRefresh();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(tr('chat_menu_refresh')),
                    ],
                  ),
                ),
                if (!isClosed)
                  PopupMenuItem(
                    value: 'close',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr('chat_menu_end'),
                          style: const TextStyle(color: Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
