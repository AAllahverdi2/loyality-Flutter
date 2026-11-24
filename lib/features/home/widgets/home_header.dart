import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    this.title,
    this.subtitle,
    this.userName,
    this.onChatTap,
    this.onNotificationsTap,
    this.hasUnreadChat = false,
    this.unreadChatCount = 0,
    this.hasUnreadNotifications = false,
    this.unreadNotificationsCount = 0,
    super.key,
  });

  final String? title;
  final String? subtitle;
  final String? userName;
  final VoidCallback? onChatTap;
  final VoidCallback? onNotificationsTap;
  final bool hasUnreadChat;
  final int unreadChatCount;
  final bool hasUnreadNotifications;
  final int unreadNotificationsCount;

  // Ionicons chatbubble-ellipses-outline (1-to-1 exact vector from Expo)
  static const String _chatbubbleEllipsesSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M87.48 380c1.2-4.38-1.43-10.47-3.94-14.86a42.63 42.63 0 00-2.54-3.8 199.81 199.81 0 01-33-110C47.64 139.09 140.72 48 255.82 48 356.2 48 440 117.54 459.57 209.85a199 199 0 014.43 41.64c0 112.41-89.49 204.93-204.59 204.93-18.31 0-43-4.6-56.47-8.37s-26.92-8.77-30.39-10.11a31.14 31.14 0 00-11.13-2.07 30.7 30.7 0 00-12.08 2.43L81.5 462.78a15.92 15.92 0 01-4.66 1.22 9.61 9.61 0 01-9.58-9.74 15.85 15.85 0 01.6-3.29z" fill="none" stroke="#F97316" stroke-linecap="round" stroke-miterlimit="10" stroke-width="32"/>
  <circle cx="160" cy="256" r="32" fill="#F97316"/>
  <circle cx="256" cy="256" r="32" fill="#F97316"/>
  <circle cx="352" cy="256" r="32" fill="#F97316"/>
</svg>
''';

  // Ionicons notifications-outline (1-to-1 exact vector from Expo)
  static const String _notificationsSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <path d="M427.68 351.43C402 320 383.87 304 383.87 217.35 383.87 138 343.35 109.73 310 96c-4.43-1.82-8.6-6-9.95-10.55C294.2 65.54 277.8 48 256 48s-38.21 17.55-44 37.47c-1.35 4.6-5.52 8.71-9.95 10.53-33.39 13.75-73.87 41.92-73.87 121.35C128.13 304 110 320 84.32 351.43 73.68 364.45 83 384 101.61 384h308.88c18.51 0 27.77-19.61 17.19-32.57zM320 384v16a64 64 0 01-128 0v-16" fill="none" stroke="#F97316" stroke-linecap="round" stroke-linejoin="round" stroke-width="32"/>
</svg>
''';

  String _getGreeting() {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) {
      return tr('home_user_greeting', {'name': name});
    }
    return tr('home_greeting');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          child: Row(
            children: [
              // headerLeft
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle ?? tr('home_welcome'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    svgString: _chatbubbleEllipsesSvg,
                    backgroundColor: cardColor,
                    headerBackgroundColor: backgroundColor,
                    isDark: isDark,
                    hasUnread: hasUnreadChat || unreadChatCount > 0,
                    unreadCount: unreadChatCount,
                    onTap: onChatTap,
                  ),
                  const SizedBox(width: 12),

                  _HeaderIconButton(
                    svgString: _notificationsSvg,
                    backgroundColor: cardColor,
                    headerBackgroundColor: backgroundColor,
                    isDark: isDark,
                    hasUnread:
                        hasUnreadNotifications || unreadNotificationsCount > 0,
                    unreadCount: unreadNotificationsCount,
                    onTap: onNotificationsTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header ikon düyməsi (oxunmamış mesaj və ya bildiriş olduqda nəbz halqası,
/// narıncı çərçivə, işıq kölgəsi və qırmızı sayğac nişanı göstərir).
class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.svgString,
    required this.backgroundColor,
    required this.headerBackgroundColor,
    required this.isDark,
    required this.hasUnread,
    required this.unreadCount,
    required this.onTap,
  });

  final String svgString;
  final Color backgroundColor;
  final Color headerBackgroundColor;
  final bool isDark;
  final bool hasUnread;
  final int unreadCount;
  final VoidCallback? onTap;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutCubic,
    );
    if (widget.hasUnread) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _HeaderIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.hasUnread && widget.hasUnread) {
      _pulseController.repeat();
    } else if (oldWidget.hasUnread && !widget.hasUnread) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentOrange = Color(0xFFF97316);
    const badgeRed = Color(0xFFDC2626);
    final activeBg = widget.hasUnread
        ? (widget.isDark
            ? const Color(0xFF2B1A10)
            : const Color(0xFFFFF3E6))
        : widget.backgroundColor;

    final badgeLabel = widget.unreadCount > 99
        ? '99+'
        : (widget.unreadCount > 0 ? '${widget.unreadCount}' : '');

    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Nəzərəçarpan nəbz (pulse) halqası
          if (widget.hasUnread)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                final t = _pulseAnimation.value;
                return IgnorePointer(
                  child: Transform.scale(
                    scale: 1.0 + (t * 0.24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentOrange.withValues(
                            alpha: (1.0 - t) * 0.55,
                          ),
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // Əsas dairəvi ikon düyməsi
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeBg,
              shape: BoxShape.circle,
              border: widget.hasUnread
                  ? Border.all(
                      color: accentOrange.withValues(
                        alpha: widget.isDark ? 0.75 : 0.65,
                      ),
                      width: 1.5,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: widget.hasUnread
                      ? accentOrange.withValues(alpha: 0.22)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: widget.hasUnread ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.onTap,
                child: Center(
                  child: SvgPicture.string(
                    widget.svgString,
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            ),
          ),

          // Oxunmamış say / parlaq bildiriş nişanı
          if (widget.hasUnread)
            Positioned(
              top: -4,
              right: -4,
              child: IgnorePointer(
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: badgeLabel.isNotEmpty ? 19 : 13,
                    minHeight: badgeLabel.isNotEmpty ? 19 : 13,
                  ),
                  padding: badgeLabel.isNotEmpty
                      ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? const Color(0xFFEF4444)
                        : badgeRed,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.headerBackgroundColor,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: badgeLabel.isNotEmpty
                      ? Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

