import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/features/home/models/app_banner.dart';
import 'package:loyallig_flutter/features/home/services/banner_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CampaignSlider extends StatefulWidget {
  const CampaignSlider({
    this.banners,
    this.onBannerTap,
    this.autoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 4),
    this.autoPlayAnimationDuration = const Duration(milliseconds: 600),
    super.key,
  });

  final List<AppBanner>? banners;
  final ValueChanged<AppBanner>? onBannerTap;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration autoPlayAnimationDuration;

  @override
  State<CampaignSlider> createState() => _CampaignSliderState();
}

class _CampaignSliderState extends State<CampaignSlider> {
  final BannerService _bannerService = BannerService();
  late final PageController _pageController;
  double _currentPage = 0.0;
  Timer? _autoPlayTimer;
  List<AppBanner> _banners = [];
  bool _loading = false;
  VoidCallback? _languageListener;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      }
    });

    _languageListener = () {
      if (widget.banners == null && mounted) {
        _loadBanners();
      }
    };
    AppLocalizations.languageNotifier.addListener(_languageListener!);

    if (widget.banners != null) {
      _banners = widget.banners!;
      _startAutoPlay();
    } else {
      _loadBanners();
    }
  }

  @override
  void didUpdateWidget(covariant CampaignSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.banners != null && widget.banners != oldWidget.banners) {
      setState(() {
        _banners = widget.banners!;
      });
      _startAutoPlay();
    }
  }

  Future<void> _loadBanners() async {
    setState(() => _loading = true);
    try {
      final list = await _bannerService.getBanners(
        languageCode: AppLocalizations.currentLanguageCode,
      );
      if (mounted) {
        setState(() {
          _banners = list;
          _loading = false;
        });
        _startAutoPlay();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _startAutoPlay() {
    if (!widget.autoPlay) return;
    _stopAutoPlay();

    final banners = widget.banners ?? _banners;
    if (banners.length <= 1) return;

    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (timer) {
      if (!_pageController.hasClients) return;
      final currentBanners = widget.banners ?? _banners;
      if (currentBanners.length <= 1) return;

      final current = _pageController.page?.round() ?? 0;
      final next = (current + 1) % currentBanners.length;

      _pageController.animateToPage(
        next,
        duration: widget.autoPlayAnimationDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void dispose() {
    if (_languageListener != null) {
      AppLocalizations.languageNotifier.removeListener(_languageListener!);
    }
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  /// Banner-ə və ya "Ətraflı" düyməsinə toxunulduqda redirectUrl-ə keçid edir
  Future<void> _handleBannerTap(AppBanner banner) async {
    widget.onBannerTap?.call(banner);

    final rawUrl = banner.redirectUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) {
      debugPrint('ℹ️ [BANNER TAP]: redirectUrl boşdur');
      return;
    }

    try {
      final formattedUrl =
          (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))
              ? rawUrl
              : 'https://$rawUrl';
      final uri = Uri.parse(formattedUrl);

      debugPrint('🌐 [LAUNCHING BANNER URL]: $uri');

      // 1. Cihazın xarici brauzerində (Chrome, Safari və s.) açırıq
      bool launched = false;
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('⚠️ [EXTERNAL APP LAUNCH FAILED]: $e');
      }

      // 2. Əgər açılmasa, platformDefault rejimində yoxlayırıq
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        } catch (e) {
          debugPrint('⚠️ [PLATFORM DEFAULT LAUNCH FAILED]: $e');
        }
      }

      // 3. Hələ də açılmayıbsa, inAppBrowserView rejimində cəhd edirik
      if (!launched) {
        try {
          await launchUrl(
            uri,
            mode: LaunchMode.inAppBrowserView,
          );
        } catch (e) {
          debugPrint('⚠️ [IN APP BROWSER LAUNCH FAILED]: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [BANNER URL ERROR]: $e');
    }
  }

  Widget _buildFallbackBackground(bool isDark) {
    return Container(
      width: double.infinity,
      height: 195,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF27272A), const Color(0xFF18181B)]
              : [const Color(0xFF334155), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.campaign_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: SizedBox(
          height: 195,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Skeleton(
              width: double.infinity,
              height: 195,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      );
    }

    final banners = widget.banners ?? _banners;

    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Horizontal Banner Slider with User-Touch Awareness
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _stopAutoPlay();
              } else if (notification is ScrollEndNotification) {
                _startAutoPlay();
              }
              return false;
            },
            child: SizedBox(
              height: 195,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final imageUrl = banner.imageUrl;
                  final hasTitle = banner.title != null && banner.title!.trim().isNotEmpty;
                  final hasSubtitle = banner.subtitle != null && banner.subtitle!.trim().isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _handleBannerTap(banner),
                      child: Container(
                        height: 195,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F1F1F)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.12,
                              ),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 1. Arxa plan şəkli
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Image.network(
                                  imageUrl,
                                  headers: ApiClient.instance.authHeaders,
                                  width: double.infinity,
                                  height: 195,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackBackground(isDark),
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: isDark
                                          ? const Color(0xFF1F1F1F)
                                          : const Color(0xFFF3F4F6),
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
                                  },
                                )
                              else
                                _buildFallbackBackground(isDark),

                              // 2. Qradiyent overlay (Soldan sağa qaraltma - mətnin aydın oxunması üçün)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.85),
                                      Colors.black.withValues(alpha: 0.72),
                                      Colors.black.withValues(alpha: 0.35),
                                      Colors.black.withValues(alpha: 0.08),
                                    ],
                                    stops: const [0.0, 0.45, 0.75, 1.0],
                                  ),
                                ),
                              ),

                              // 3. Sol tərəfdəki Məlumatlar (Title, Subtitle və Sarı Ətraflı düyməsi)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      width: constraints.maxWidth * 0.62,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasTitle)
                                                Text(
                                                  banner.title!.trim(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.25,
                                                    letterSpacing: -0.3,
                                                  ),
                                                ),
                                              if (hasSubtitle) ...[
                                                const SizedBox(height: 6),
                                                Text(
                                                  banner.subtitle!.trim(),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.90),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),

                                          // Sarı "Ətraflı" düyməsi
                                          GestureDetector(
                                            onTap: () =>
                                                _handleBannerTap(banner),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 7,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFD600),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFFFD600)
                                                            .withValues(
                                                                alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                tr('home_more_details'),
                                                style: const TextStyle(
                                                  color: Color(0xFF111827),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Animated Pagination Dots
          if (banners.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (index) {
                final distance = (_currentPage - index).abs();
                final progress = (1.0 - distance).clamp(0.0, 1.0);

                // Aktiv nöqtə uzanmış həb forması (24px), qeyri-aktivlər kiçik dairə (8px)
                final dotWidth = 8.0 + (16.0 * progress);
                final activeColor =
                    isDark ? Colors.white : const Color(0xFF111827);
                const inactiveColor = Color(0xFFD1D5DB);
                final dotColor =
                    Color.lerp(inactiveColor, activeColor, progress) ??
                        inactiveColor;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: dotWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
