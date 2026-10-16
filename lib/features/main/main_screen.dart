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

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final Set<int> _loadedTabs = {};

  @override
  void initState() {
    super.initState();
    MainScreen._currentState = this;
    _currentIndex = widget.initialIndex;
    _loadedTabs.add(_currentIndex);
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
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
      _loadedTabs.add(index);
    });
    if (index == 2) {
      // İstifadəçi menyudan Sevimlilər tabına kliklədikdə ən son siyahını dərhal gətirsin
      PartnersService.notifyFavoritesChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.getOverlayStyle(isDark),
      child: ValueListenableBuilder<String>(
        valueListenable: AppLocalizations.languageNotifier,
        builder: (context, currentLang, _) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _loadedTabs.contains(0)
                    ? HomeScreen(
                        key: ValueKey('home_$currentLang'),
                        onNavigateToTab: _onTabTapped,
                      )
                    : const SizedBox.shrink(),
                _loadedTabs.contains(1)
                    ? HistoryScreen(
                        key: ValueKey('history_$currentLang'),
                      )
                    : const SizedBox.shrink(),
                _loadedTabs.contains(2)
                    ? FavoritesScreen(
                        key: ValueKey('favorites_$currentLang'),
                        isActive: _currentIndex == 2,
                      )
                    : const SizedBox.shrink(),
                _loadedTabs.contains(3)
                    ? ProfileScreen(
                        key: ValueKey('profile_$currentLang'),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            bottomNavigationBar: AppBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
          );
        },
      ),
    );
  }
}

