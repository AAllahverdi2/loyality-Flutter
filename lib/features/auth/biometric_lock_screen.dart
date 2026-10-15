import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/widgets/azera_logo.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({
    this.isOverlay = false,
    this.onUnlocked,
    super.key,
  });

  final bool isOverlay;
  final VoidCallback? onUnlocked;

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricService _biometricService = BiometricService.instance;
  bool _authenticating = false;
  String? _errorMessage;
  String _biometricName = 'Biometrika';

  @override
  void initState() {
    super.initState();
    _loadBiometricName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuth();
    });
  }

  Future<void> _loadBiometricName() async {
    final name = await _biometricService.getBiometricDisplayName();
    if (mounted) {
      setState(() => _biometricName = name);
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_authenticating) return;

    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    final result = await _biometricService.authenticate(
      localizedReason: tr('biometric_reason'),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _authenticating = false);
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else if (widget.isOverlay) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        _authenticating = false;
        if (result.status != BiometricAuthStatus.canceled) {
          _errorMessage = result.errorMessage ?? tr('common_error');
        }
      });
    }
  }

  void _handleFallbackToPassword() {
    // Cari sessiyanı təmizləyib Login ekranına göndəririk
    ApiClient.instance.clearAuthToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final isFace = _biometricName.toLowerCase().contains('face');

    return PopScope(
      canPop: false, // Kilid ekranını geri düyməsi ilə keçmək olmaz
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo
                const AzeraLogo(width: 130, height: 130),
                const SizedBox(height: 36),

                // Biometric Lock Icon
                GestureDetector(
                  onTap: _authenticating ? null : _triggerBiometricAuth,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1F1F1F)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC91C1C).withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC91C1C).withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
                      size: 52,
                      color: const Color(0xFFC91C1C),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                Text(
                  tr('biometric_unlock_title'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  tr('biometric_unlock_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: secondaryTextColor,
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // Action Buttons
                PrimaryButton(
                  label: _authenticating
                      ? tr('common_loading')
                      : '${tr('biometric_unlock_btn')} ($_biometricName)',
                  onPressed: _authenticating ? () {} : _triggerBiometricAuth,
                  height: 52,
                  borderRadius: 14,
                ),
                const SizedBox(height: 14),

                // Fallback to standard login
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    onPressed: _handleFallbackToPassword,
                    icon: const Icon(Icons.lock_open_rounded, size: 18),
                    label: Text(
                      tr('biometric_use_password'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.base,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
