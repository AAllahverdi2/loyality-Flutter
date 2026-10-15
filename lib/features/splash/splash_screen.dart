import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/features/auth/biometric_lock_screen.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/register_screen.dart';
import 'package:loyallig_flutter/features/auth/widgets/azera_logo.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSessionAndBiometrics();
  }

  Future<void> _checkSessionAndBiometrics() async {
    try {
      final hasSession = await TokenStorage.hasValidSession();

      if (!hasSession) {
        if (mounted) setState(() => _isChecking = false);
        return;
      }

      // İstifadəçinin aktiv sessiyası var
      final biometricService = BiometricService.instance;
      final isBiometricEnabled = await biometricService.isBiometricEnabled();
      final canUseBiometrics = await biometricService.canUseBiometrics();

      if (!mounted) return;

      if (isBiometricEnabled && canUseBiometrics) {
        // Biometrik kilid ekranına yönləndiririk
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const BiometricLockScreen(),
          ),
        );
      } else {
        // Biometrika aktiv deyil, birbaşa ana ekrana keçid edirik
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const MainScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Theme(
        data: AppTheme.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // Center Logo
                const Expanded(
                  child: Center(
                    child: AzeraLogo(width: 260, height: 300),
                  ),
                ),

                // Bottom Buttons with safe padding (yalnız sessiya yoxdursa görünür)
                if (!_isChecking)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PrimaryButton(
                          label: tr('splash_login'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: tr('splash_register'),
                          outlined: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC91C1C)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
