import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/core/widgets/network_error_view.dart';
import 'package:loyallig_flutter/features/auth/biometric_lock_screen.dart';
import 'package:loyallig_flutter/features/chat/services/support_conversations_store.dart';
import 'package:loyallig_flutter/features/notifications/services/notifications_store.dart';
import 'package:loyallig_flutter/features/notifications/services/push_notification_service.dart';
import 'package:loyallig_flutter/features/notifications/widgets/in_app_notification_overlay.dart';
import 'package:loyallig_flutter/features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.init();
  await AppTheme.init();
  await NotificationsStore.instance.initPreferences();
  await PushNotificationService.instance.init();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;
  bool _isLockScreenShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(SupportConversationsStore.instance.initGlobalSession());
    unawaited(NotificationsStore.instance.initGlobalSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Əgər hazırda biometrik dialoq və ya xarici əməliyyat (kamera/fayl) aktiv deyilsə, arxa plana keçid vaxtını saxlayırıq
      if (!BiometricService.instance.isAuthenticating &&
          !BiometricService.instance.isLockSuppressed) {
        _pausedTime = DateTime.now();
      } else {
        _pausedTime = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      unawaited(SupportConversationsStore.instance.onAppResumed());
      unawaited(NotificationsStore.instance.onAppResumed());
      if (_pausedTime != null &&
          !BiometricService.instance.isAuthenticating &&
          !BiometricService.instance.isLockSuppressed) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        _pausedTime = null;

        // Tətbiqanılır
        if (elapsed.inSeconds >= 2) {
          _checkAndShowLockScreen();
        }
      } else {
        _pausedTime = null;
      }
    }
  }

  Future<void> _checkAndShowLockScreen() async {
    if (_isLockScreenShowing) return;

    final hasSession = await TokenStorage.hasValidSession();
    if (!hasSession) return;

    final hasPin = await TokenStorage.hasPinCode();
    final isEnabled = await BiometricService.instance.isBiometricEnabled();
    final canUse = await BiometricService.instance.canUseBiometrics();

    if (hasPin || (isEnabled && canUse)) {
      _isLockScreenShowing = true;
      navigatorKey.currentState
          ?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => BiometricLockScreen(
            isOverlay: true,
            onUnlocked: () {
              _isLockScreenShowing = false;
              navigatorKey.currentState?.pop();
            },
          ),
        ),
      )
          .then((_) {
        _isLockScreenShowing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, currentLang, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeModeNotifier,
          builder: (context, currentMode, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'Azera Loyallıq',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: currentMode,
              locale: Locale(currentLang),
              supportedLocales: const [
                Locale('az'),
                Locale('en'),
                Locale('ru'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return AnnotatedRegion<SystemUiOverlayStyle>(
                  value: AppTheme.getOverlayStyle(isDark),
                  child: Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const InAppNotificationOverlay(),
                      const GlobalNetworkErrorOverlay(),
                    ],
                  ),
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
