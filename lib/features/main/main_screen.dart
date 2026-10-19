import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/core/widgets/app_bottom_nav.dart';
import 'package:loyallig_flutter/features/auth/widgets/biometric_prompt_sheet.dart';
import 'package:loyallig_flutter/features/favorites/favorites_screen.dart';
import 'package:loyallig_flutter/features/history/history_screen.dart';
import 'package:loyallig_flutter/features/home/home_screen.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';
import 'package:loyallig_flutter/features/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    this.initialIndex = 0,
    super.key,
  });

  final int initialIndex;

  static _MainScreenState? _currentState;

  static void navigateToTab(BuildContext context, int index) {
    if (_currentState != null && Navigator.of(context).canPop()) {
      _currentState!._onTabTapped(index);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => MainScreen(initialIndex: index),
        ),
        (route) => false,
      );
    }
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  final Set<int> _loadedTabs = {};

  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isTransitioning = false;
  int? _animatingFromTab;
  double _screenWidth = 375.0;

  @override
  void initState() {
    super.initState();
    MainScreen._currentState = this;
    _currentIndex = widget.initialIndex;
    _loadedTabs.add(0); // Home hər zaman yüklənir
    _loadedTabs.add(_currentIndex);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = _slideAnimation.value;
          });
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isTransitioning = false;
              _animatingFromTab = null;
              if (_currentIndex == 0) {
                _dragOffset = 0.0;
              }
            });
          }
        }
      });

    _slideAnimation = const AlwaysStoppedAnimation<double>(0.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        BiometricPromptSheet.showIfEligible(context);
      }
    });
  }

  @override
  void dispose() {
    if (MainScreen._currentState == this) {
      MainScreen._currentState = null;
    }
    _animController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (!mounted) return;
    if (index == _currentIndex && !_isTransitioning) return;

    if (index == 2) {
      // İstifadəçi menyudan Sevimlilər tabına kliklədikdə ən son siyahını dərhal gətirsin
      PartnersService.notifyFavoritesChanged();
    }

    // Əgər sub-tab-dan Home-a (0) qayıdırsa, yumşaq sürüşmə animasiyası ilə qayıtsın
    if (index == 0 && _currentIndex != 0) {
      _animateToHome();
      return;
    }

    // Əgər Home-dan sub-tab-a keçirsə, yumşaq sürüşmə ilə açılsın
    if (index != 0 && _currentIndex == 0) {
      _animateFromHomeToTab(index);
      return;
    }

    // Sub-tab-lar arası keçid (məsələn, Tarixçədən Sevimlilərə)
    setState(() {
      _animController.stop();
      _isTransitioning = false;
      _animatingFromTab = null;
      _dragOffset = 0.0;
      _currentIndex = index;
      _loadedTabs.add(index);
    });
  }

  void _animateToHome() {
    if (_isTransitioning) return;
    _animController.stop();
    _isTransitioning = true;
    _animatingFromTab = _currentIndex;

    setState(() {
      _currentIndex = 0;
    });

    final remainingDistance = (_screenWidth - _dragOffset).clamp(0.0, _screenWidth);
    final remainingRatio = (remainingDistance / _screenWidth).clamp(0.25, 1.0);
    final durationMs = (240 * remainingRatio).toInt();

    _animController.duration = Duration(milliseconds: durationMs);
    _slideAnimation = Tween<double>(begin: _dragOffset, end: _screenWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  void _animateFromHomeToTab(int targetIndex) {
    if (_isTransitioning) return;
    _animController.stop();
    _isTransitioning = true;
    _animatingFromTab = targetIndex;
    _loadedTabs.add(targetIndex);

    setState(() {
      _currentIndex = targetIndex;
      _dragOffset = _screenWidth;
    });

    _animController.duration = const Duration(milliseconds: 240);
    _slideAnimation = Tween<double>(begin: _screenWidth, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isTransitioning) return;
    _animController.stop();
    _isDragging = true;
    _dragOffset = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isTransitioning) return;
    // Yalnız sağa çəkilişdə ekranı sağa hərəkət etdiririk
    if (details.delta.dx > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _screenWidth);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging || _isTransitioning) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    // Əgər istifadəçi telefonu sağa sürətlə çəkibsə (velocity > 250)
    // və ya ekranın 20%-dən çoxunu sürükləyibsə, Home səhifəsinə yumşaq qayıdırıq
    final shouldGoHome = velocity > 250 || _dragOffset > (_screenWidth * 0.20);

    if (shouldGoHome) {
      _animateToHome();
    } else {
      _animateCancelDrag();
    }
  }

  void _onHorizontalDragCancel() {
    if (!_isDragging || _isTransitioning) return;
    _isDragging = false;
    _animateCancelDrag();
  }

  void _animateCancelDrag() {
    _isTransitioning = true;
    final cancelRatio = (_dragOffset / _screenWidth).clamp(0.2, 1.0);
    final durationMs = (180 * cancelRatio).toInt();

    _animController.duration = Duration(milliseconds: durationMs);
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);

    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 375.0;
        final progress = (_dragOffset / _screenWidth).clamp(0.0, 1.0);
        final homeParallax = -0.20 * _screenWidth * (1.0 - progress);
        final scrimOpacity = 0.12 * (1.0 - progress);

        final activeSubTab = _animatingFromTab ?? _currentIndex;
        final showSubTabLayer = activeSubTab != 0 || _isTransitioning;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.getOverlayStyle(isDark),
          child: ValueListenableBuilder<String>(
            valueListenable: AppLocalizations.languageNotifier,
            builder: (context, currentLang, _) {
              return PopScope(
                canPop: _currentIndex == 0 && !_isTransitioning,
                onPopInvokedWithResult: (didPop, _) {
                  if (didPop) return;
                  if (_currentIndex != 0) {
                    _animateToHome();
                  }
                },
                child: Scaffold(
                  backgroundColor: backgroundColor,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. BASE LAYER: HomeScreen (Tab 0) - həmişə yaddaşda və arxa planda hazır
                      Positioned.fill(
                        child: Offstage(
                          offstage: !_loadedTabs.contains(0),
                          child: TickerMode(
                            enabled: _currentIndex == 0 || showSubTabLayer,
                            child: IgnorePointer(
                              ignoring: _currentIndex != 0,
                              child: Transform.translate(
                                offset: Offset(
                                  _currentIndex == 0 && !_isTransitioning
                                      ? 0.0
                                      : homeParallax,
                                  0,
                                ),
                                child: HomeScreen(
                                  key: ValueKey('home_$currentLang'),
                                  onNavigateToTab: _onTabTapped,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. SCRIM (Tündləşdirmə) - Home səhifəsinin üzərində dərinlik effekti
                      if (showSubTabLayer && progress < 0.99)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: Colors.black.withValues(alpha: scrimOpacity),
                            ),
                          ),
                        ),

                      // 3. TOP LAYER: Sub-tab-lar (Tarixçə, Sevimlilər, Profil)
                      if (showSubTabLayer)
                        Positioned.fill(
                          child: Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                boxShadow: _dragOffset > 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.14),
                                          blurRadius: 16,
                                          spreadRadius: 1,
                                          offset: const Offset(-4, 0),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onHorizontalDragStart: _onHorizontalDragStart,
                                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                                onHorizontalDragEnd: _onHorizontalDragEnd,
                                onHorizontalDragCancel: _onHorizontalDragCancel,
                                child: IndexedStack(
                                  index: (activeSubTab - 1).clamp(0, 2),
                                  children: [
                                    _loadedTabs.contains(1)
                                        ? HistoryScreen(
                                            key: ValueKey('history_$currentLang'),
                                          )
                                        : const SizedBox.shrink(),
                                    _loadedTabs.contains(2)
                                        ? FavoritesScreen(
                                            key: ValueKey('favorites_$currentLang'),
                                            isActive: _currentIndex == 2 &&
                                                !_isTransitioning,
                                          )
                                        : const SizedBox.shrink(),
                                    _loadedTabs.contains(3)
                                        ? ProfileScreen(
                                            key: ValueKey('profile_$currentLang'),
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  bottomNavigationBar: AppBottomNav(
                    currentIndex: _currentIndex,
                    onTap: _onTabTapped,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


