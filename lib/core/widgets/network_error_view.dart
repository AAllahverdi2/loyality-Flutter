import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';

/// Üzərindən xətt çəkilmiş Wi-Fi işarəsi ilə şəbəkə xətası görünüşü
class NetworkErrorView extends StatefulWidget {
  const NetworkErrorView({
    super.key,
    required this.onRetry,
    this.compact = false,
    this.title,
    this.description,
    this.showRetryStatusFeedback = false,
  });

  final Future<bool> Function() onRetry;
  final bool compact;
  final String? title;
  final String? description;
  final bool showRetryStatusFeedback;

  @override
  State<NetworkErrorView> createState() => _NetworkErrorViewState();
}

class _NetworkErrorViewState extends State<NetworkErrorView> {
  bool _isRetrying = false;
  bool _stillOfflineHint = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _stillOfflineHint = false;
    });

    final ok = await widget.onRetry();
    if (!mounted) return;
    setState(() {
      _isRetrying = false;
      _stillOfflineHint = widget.showRetryStatusFeedback && !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final outerCircleColor = isDark
        ? AppColors.base.withValues(alpha: 0.12)
        : AppColors.base.withValues(alpha: 0.08);
    final innerCircleColor = isDark
        ? AppColors.base.withValues(alpha: 0.22)
        : AppColors.base.withValues(alpha: 0.14);

    final badgeOuterSize = widget.compact ? 84.0 : 124.0;
    final badgeInnerSize = widget.compact ? 62.0 : 88.0;
    final iconSize = widget.compact ? 32.0 : 44.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 20 : 32,
          vertical: widget.compact ? 24 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Üzərindən xətt çəkilmiş Wi-Fi ikonu
              Container(
                width: badgeOuterSize,
                height: badgeOuterSize,
                decoration: BoxDecoration(
                  color: outerCircleColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: badgeInnerSize,
                  height: badgeInnerSize,
                  decoration: BoxDecoration(
                    color: innerCircleColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: iconSize,
                    color: AppColors.base,
                  ),
                ),
              ),
              SizedBox(height: widget.compact ? 18 : 28),

              // Başlıq
              Text(
                widget.title ?? tr('network_error_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.compact ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // İzah mətni
              Text(
                widget.description ?? tr('network_error_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: widget.compact ? 13.5 : 14.5,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
              SizedBox(height: widget.compact ? 20 : 28),

              // Yenidən cəhd et düyməsi
              SizedBox(
                width: double.infinity,
                height: widget.compact ? 46 : 52,
                child: ElevatedButton(
                  onPressed: _isRetrying ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.base,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.base.withValues(alpha: 0.7),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isRetrying)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(Icons.refresh_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isRetrying
                            ? tr('network_checking')
                            : tr('network_error_retry'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_stillOfflineHint) ...[
                const SizedBox(height: 14),
                Text(
                  tr('network_still_offline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Şəbəkə kəsildikdə tətbiqin bütün ekranları üzərində görünən tam ekran xəta səhifəsi
class GlobalNetworkErrorOverlay extends StatelessWidget {
  const GlobalNetworkErrorOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkMonitor.instance.isOfflineNotifier,
      builder: (context, isOffline, _) {
        if (!isOffline) {
          return const SizedBox.shrink();
        }

        FocusManager.instance.primaryFocus?.unfocus();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor =
            isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

        return Positioned.fill(
          child: PopScope(
            canPop: false,
            child: Scaffold(
              backgroundColor: backgroundColor,
              body: SafeArea(
                child: NetworkErrorView(
                  showRetryStatusFeedback: true,
                  onRetry: () => NetworkMonitor.instance.checkConnection(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

