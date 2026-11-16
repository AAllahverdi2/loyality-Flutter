import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/services/file_service.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessageBubble extends StatelessWidget {
  final SupportChatMessage message;
  final FileService fileService;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.fileService,
  });

  String? _resolveAttachmentUrl() {
    if (message.attachmentFileId != null &&
        message.attachmentFileId!.isNotEmpty) {
      return fileService.getFileUrl(message.attachmentFileId!);
    }
    final rawUrl = message.attachmentUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      return rawUrl.startsWith('http')
          ? rawUrl
          : '${ApiEndpoints.baseUrl}$rawUrl';
    }
    return null;
  }

  void _openFullScreenImage(
    BuildContext context,
    String imageUrl,
    String heroTag,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _ChatFullScreenImageViewer(
              imageUrl: imageUrl,
              headers: fileService.authHeaders,
              heroTag: heroTag,
              timeStr: message.timeStr,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemMessageBanner(BuildContext context, bool isDark) {
    final raw = message.content.trim();
    String? titlePart;
    String? detailPart;

    final lower = raw.toLowerCase();
    final operatorMarkerIdx = lower.indexOf('operator:');
    if (operatorMarkerIdx != -1) {
      final before = raw
          .substring(0, operatorMarkerIdx)
          .trim()
          .replaceAll(RegExp(r'[.\s]+$'), '');
      final after = raw.substring(operatorMarkerIdx + 'operator:'.length).trim();
      if (before.isNotEmpty && after.isNotEmpty) {
        titlePart = before;
        detailPart = after;
      }
    }

    const accentColor = Color(0xFF10B981);
    final bgColor = isDark
        ? accentColor.withValues(alpha: 0.10)
        : const Color(0xFFECFDF5);
    final borderColor = isDark
        ? accentColor.withValues(alpha: 0.28)
        : accentColor.withValues(alpha: 0.32);
    final primaryTextColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF065F46);
    final subtitleColor =
        isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
    final timeColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF047857).withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.20 : 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    size: 17,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: titlePart != null && detailPart != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    titlePart,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  message.timeStr,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: timeColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              detailPart,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              raw,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              message.timeStr,
                              style: TextStyle(
                                fontSize: 10,
                                color: timeColor,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (message.isSystemMessage) {
      return _buildSystemMessageBanner(context, isDark);
    }

    final textColor =
        isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final isUser = message.isUser;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.78;
    final attachmentUrl = _resolveAttachmentUrl();
    final hasAttachment = attachmentUrl != null;
    final heroTag = 'chat_img_${message.id}_${attachmentUrl ?? ''}';
    final trimmedContent = message.content.trim();
    final isPlaceholderCaption =
        hasAttachment &&
        (trimmedContent == '📷 Şəkil' ||
            trimmedContent == '📷 Photo' ||
            trimmedContent == '📷 Фото' ||
            trimmedContent == tr('chat_photo_message'));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.base
              : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
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
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Əgər şəkil əlavəsi varsa
            if (hasAttachment) ...[
              GestureDetector(
                onTap: () =>
                    _openFullScreenImage(context, attachmentUrl, heroTag),
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      attachmentUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 180,
                      headers: fileService.authHeaders,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        color: Colors.grey.withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, size: 36),
                        ),
                      ),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          height: 150,
                          color: Colors.grey.withValues(alpha: 0.1),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (message.content.isNotEmpty && !isPlaceholderCaption)
                const SizedBox(height: 6),
            ],

            if (message.content.isNotEmpty && !isPlaceholderCaption)
              _LinkifiedMessageText(
                text: message.content,
                baseStyle: TextStyle(
                  fontSize: 14.5,
                  height: 1.35,
                  color: isUser ? Colors.white : textColor,
                ),
                linkColor: isUser
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF2563EB)),
                linkFontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
              ),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  message.timeStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.75)
                        : secondaryTextColor,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  if (message.isSending)
                    SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    )
                  else if (message.hasFailed)
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: Color(0xFFEF4444),
                    )
                  else
                    Icon(
                      Icons.done_all_rounded,
                      size: 15,
                      color: message.isSeen
                          ? const Color(0xFF34B7F1)
                          : const Color(0xFFD1D5DB).withValues(alpha: 0.78),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatFullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final Map<String, String> headers;
  final String heroTag;
  final String timeStr;

  const _ChatFullScreenImageViewer({
    required this.imageUrl,
    required this.headers,
    required this.heroTag,
    required this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: SafeArea(
        child: Stack(
          children: [
            // Boş sahəyə toxunduqda bağlansın
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
                          fit: BoxFit.contain,
                          headers: headers,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.white70,
                              size: 56,
                            ),
                          ),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Üst panel (Saat və Bağla düyməsi)
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (timeStr.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageTextSegment {
  final String text;
  final String? url;

  const _MessageTextSegment({required this.text, this.url});
}

class _LinkifiedMessageText extends StatefulWidget {
  final String text;
  final TextStyle baseStyle;
  final Color linkColor;
  final FontWeight linkFontWeight;

  const _LinkifiedMessageText({
    required this.text,
    required this.baseStyle,
    required this.linkColor,
    this.linkFontWeight = FontWeight.w500,
  });

  @override
  State<_LinkifiedMessageText> createState() => _LinkifiedMessageTextState();
}

class _LinkifiedMessageTextState extends State<_LinkifiedMessageText> {
  static final RegExp _linkRegex = RegExp(
    r'('
    r"""https?:\/\/[^\s<>"'\u00A0]+"""
    r'|'
    r"""\bwww\.[^\s<>"'\u00A0]+"""
    r'|'
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'
    r'|'
    r"""(?<![@.\/\w-])(?:[A-Za-z0-9-]+\.)+(?:az|com|net|org|ru|tr|io|co|me|info|biz|edu|gov|dev|app|ai|gg|tv|ly|cc|be|de|uk|fr|ua|ge|kz)(?:[/?#][^\s<>"'\u00A0]*)?(?![\w-])"""
    r')',
    caseSensitive: false,
  );

  List<_MessageTextSegment> _segments = const [];
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _rebuildSegments();
  }

  @override
  void didUpdateWidget(covariant _LinkifiedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _rebuildSegments();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  String _trimTrailingPunctuation(String raw) {
    var result = raw;
    while (result.isNotEmpty) {
      final last = result[result.length - 1];
      if (last == '.' ||
          last == ',' ||
          last == '!' ||
          last == '?' ||
          last == ';' ||
          last == ':' ||
          last == '"' ||
          last == '\'' ||
          last == '»' ||
          last == '>' ||
          last == ']' ||
          last == '}') {
        result = result.substring(0, result.length - 1);
        continue;
      }
      if (last == ')') {
        final openCount = '('.allMatches(result).length;
        final closeCount = ')'.allMatches(result).length;
        if (closeCount > openCount) {
          result = result.substring(0, result.length - 1);
          continue;
        }
      }
      break;
    }
    return result;
  }

  void _rebuildSegments() {
    _disposeRecognizers();
    final text = widget.text;
    final matches = _linkRegex.allMatches(text);
    if (matches.isEmpty) {
      _segments = [_MessageTextSegment(text: text)];
      return;
    }

    final parsed = <_MessageTextSegment>[];
    var cursor = 0;

    for (final match in matches) {
      if (match.start < cursor) continue;

      final rawMatch = match.group(0) ?? '';
      final cleanLink = _trimTrailingPunctuation(rawMatch);
      if (cleanLink.isEmpty) continue;

      if (match.start > cursor) {
        parsed.add(
          _MessageTextSegment(text: text.substring(cursor, match.start)),
        );
      }

      parsed.add(_MessageTextSegment(text: cleanLink, url: cleanLink));
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openLink(cleanLink);
      _recognizers.add(recognizer);

      cursor = match.start + cleanLink.length;
    }

    if (cursor < text.length) {
      parsed.add(_MessageTextSegment(text: text.substring(cursor)));
    }

    _segments = parsed;
  }

  Future<void> _openLink(String rawLink) async {
    try {
      final isEmail =
          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(rawLink) &&
          !RegExp(r'^https?://', caseSensitive: false).hasMatch(rawLink);

      final Uri? uri = isEmail
          ? Uri(scheme: 'mailto', path: rawLink)
          : (Uri.tryParse(
                RegExp(r'^https?://', caseSensitive: false).hasMatch(rawLink)
                    ? rawLink
                    : 'https://$rawLink',
              ) ??
              Uri.tryParse(
                Uri.encodeFull(
                  RegExp(r'^https?://', caseSensitive: false).hasMatch(rawLink)
                      ? rawLink
                      : 'https://$rawLink',
                ),
              ));

      if (uri == null) return;

      var launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: isEmail
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication,
        );
      } catch (_) {}

      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched && !isEmail) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        } catch (_) {}
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(tr('chat_link_open_error')),
            ),
          );
      }
    } catch (e) {
      debugPrint('❌ [CHAT LINK OPEN ERROR]: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recognizers.isEmpty) {
      return Text(widget.text, style: widget.baseStyle);
    }

    final linkStyle = widget.baseStyle.copyWith(
      color: widget.linkColor,
      fontWeight: widget.linkFontWeight,
      decoration: TextDecoration.underline,
      decorationColor: widget.linkColor,
      decorationThickness: 1.4,
    );

    var recognizerIndex = 0;
    return Text.rich(
      TextSpan(
        style: widget.baseStyle,
        children: _segments.map((seg) {
          if (seg.url == null) {
            return TextSpan(text: seg.text);
          }
          final recognizer = _recognizers[recognizerIndex++];
          return TextSpan(
            text: seg.text,
            style: linkStyle,
            recognizer: recognizer,
            mouseCursor: SystemMouseCursors.click,
          );
        }).toList(),
      ),
    );
  }
}

