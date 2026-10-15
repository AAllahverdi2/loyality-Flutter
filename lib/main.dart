import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/features/auth/biometric_lock_screen.dart';
import 'package:loyallig_flutter/features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.init();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Əgər hazırda biometrik dialoq aktiv deyilsə, arxa plana keçid vaxtını saxlayırıq
      if (!BiometricService.instance.isAuthenticating) {
        _pausedTime = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null && !BiometricService.instance.isAuthenticating) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        _pausedTime = null;

        // Tətbiq 2 saniyədən çox arxa planda qaldıqda biometrik kilid yoxlanılır
        if (elapsed.inSeconds >= 2) {
          _checkAndShowLockScreen();
        }
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
              title: 'Azera Holding',
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
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
