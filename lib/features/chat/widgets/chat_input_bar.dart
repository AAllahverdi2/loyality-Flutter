import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class ChatInputBar extends StatelessWidget {
  static const int maxMessageLength = 4000;

  final TextEditingController controller;
  final bool isClosed;
  final bool isSending;
  final bool isUploadingAttachment;
  final VoidCallback onPickAttachment;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isClosed,
    required this.isSending,
    required this.isUploadingAttachment,
    required this.onPickAttachment,
    required this.onSend,
  });

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

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
              width: 42,
              height: 42,
              alignment: Alignment.center,
              child: isUploadingAttachment
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_photo_alternate_outlined,
                          size: 26),
                      color: isClosed
                          ? secondaryTextColor.withValues(alpha: 0.5)
                          : secondaryTextColor,
                      onPressed: isClosed ? null : onPickAttachment,
                    ),
            ),

            // Giriş sahəsi
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final charCount = value.text.length;
                  final showCounter = !isClosed && charCount >= 200;
                  final isAtLimit = charCount >= maxMessageLength;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (showCounter)
                        Padding(
                          padding: const EdgeInsets.only(right: 14, bottom: 3),
                          child: Text(
                            '$charCount / $maxMessageLength',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isAtLimit
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isAtLimit
                                  ? const Color(0xFFEF4444)
                                  : secondaryTextColor,
                            ),
                          ),
                        ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F1F1F)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isAtLimit
                                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.transparent),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: maxMessageLength,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(maxMessageLength),
                          ],
                          enabled: !isClosed,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                          ),
                          cursorColor: AppColors.base,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: false,
                            fillColor: Colors.transparent,
                            counterText: '',
                            hintText: isClosed
                                ? tr('chat_status_closed')
                                : tr('chat_input_hint'),
                            hintStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 14.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Göndər düyməsi
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final trimmed = value.text.trim();
                final canSend =
                    trimmed.isNotEmpty &&
                    trimmed.length <= maxMessageLength &&
                    !isClosed &&
                    !isSending;
                return Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend
                        ? AppColors.base
                        : (isDark
                            ? const Color(0xFF27272A)
                            : const Color(0xFFE5E7EB)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: canSend ? onSend : null,
                      child: Center(
                        child: isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Padding(
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
    );
  }
}

