import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/services/pin_code_service.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/widgets/azera_logo.dart';
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
  final PinCodeService _pinCodeService = PinCodeService.instance;

  String _currentInput = '';
  bool _verifyingPin = false;
  bool _authenticatingBiometric = false;
  bool _hasBiometricsAvailable = false;
  String? _errorMessage;
  String _biometricName = 'Biometrika';

  @override
  void initState() {
    super.initState();
    _initBiometricsAndTrigger();
  }

  Future<void> _initBiometricsAndTrigger() async {
    final name = await _biometricService.getBiometricDisplayName();
    final canUse = await _biometricService.canUseBiometrics();
    final isEnabled = await _biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _biometricName = name;
        _hasBiometricsAvailable = canUse && isEnabled;
      });
    }

    // Ekran açılan kimi avtomatik olaraq Face ID / Barmaq izi skanını işə salırıq (Birbank kimi)
    if (canUse && isEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerBiometricAuth();
      });
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_authenticatingBiometric || _verifyingPin) return;

    setState(() {
      _authenticatingBiometric = true;
      _errorMessage = null;
    });

    try {
      final result = await _biometricService.authenticate(
        localizedReason: tr('biometric_reason'),
      );

      if (!mounted) return;

      if (result.isSuccess) {
        setState(() => _authenticatingBiometric = false);
        _handleSuccessUnlock();
      } else {
        setState(() {
          _authenticatingBiometric = false;
          // İstifadəçi ləğv etdikdə xəta mətni göstərmirik, rahatlıqla PIN kod yığsın
          if (result.status != BiometricAuthStatus.canceled) {
            _errorMessage = result.errorMessage;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _authenticatingBiometric = false);
      }
    }
  }

  void _onDigitTap(String digit) {
    if (_verifyingPin || _currentInput.length >= 4) return;
    HapticFeedback.lightImpact();

    setState(() {
      _currentInput += digit;
      _errorMessage = null;
    });

    if (_currentInput.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspaceTap() {
    if (_verifyingPin || _currentInput.isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    if (_verifyingPin) return;

    final pinToVerify = _currentInput;
    setState(() {
      _verifyingPin = true;
      _errorMessage = null;
    });

    try {
      final isSuccess = await _pinCodeService.verifyPinCode(pinToVerify);

      if (!mounted) return;

      if (isSuccess) {
        setState(() => _verifyingPin = false);
        _handleSuccessUnlock();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _verifyingPin = false;
          _currentInput = '';
          _errorMessage = tr('pin_code_invalid');
        });
      }
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _verifyingPin = false;
        _currentInput = '';
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _handleSuccessUnlock() {
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
  }

  void _handleFallbackToPassword() {
    ApiClient.instance.clearAuthToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF9FAFB);
    const textColor = Color(0xFF111827);
    const secondaryTextColor = Color(0xFF6B7280);

    return Theme(
      data: AppTheme.light,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: PopScope(
          canPop: false, // Kilid ekranını geri düyməsi ilə keçmək olmaz
          child: Scaffold(
            backgroundColor: backgroundColor,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 24),

                              // Loqo
                              const AzeraLogo(width: 100, height: 70),
                              const SizedBox(height: 18),

                              // Başlıq
                              Text(
                                tr('pin_code_enter_title'),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // İzah mətni
                              Text(
                                tr('pin_code_enter_desc'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // PIN 4 Dairə İndikatoru (Dots)
                              _buildPinIndicator(),

                              // Xəta və ya Yoxlanılır bildirişi
                              const SizedBox(height: 16),
                              _buildStatusMessage(),

                              const Spacer(),

                              // Rəqəmlər Klaviaturası (Birbank Style)
                              _buildKeypad(),
                              const SizedBox(height: 16),

                              // Şifrə ilə daxil ol (Fallback)
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: TextButton.icon(
                                  onPressed: _handleFallbackToPassword,
                                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                                  label: Text(
                                    tr('pin_code_use_password'),
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
                              const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  // 4 rəqəmli PIN nöqtələri
  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _currentInput.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 18 : 16,
          height: isFilled ? 18 : 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? const Color(0xFFC91C1C) : Colors.transparent,
            border: Border.all(
              color: isFilled ? const Color(0xFFC91C1C) : const Color(0xFFD1D5DB),
              width: 2,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: const Color(0xFFC91C1C).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // Status və ya Xəta Mesajı
  Widget _buildStatusMessage() {
    if (_verifyingPin) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.base),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tr('pin_code_verifying'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.base,
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
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
              size: 16,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox(height: 20);
  }

  // Rəqəmlər Klaviaturası (Keypad)
  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 14),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 14),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Sol düymə: Biometrika ikonu (Face ID / Barmaq izi)
            _buildSpecialKey(
              icon: Icons.fingerprint_rounded,
              isEnabled: _hasBiometricsAvailable && !_verifyingPin,
              onTap: _triggerBiometricAuth,
              tooltip: _biometricName,
            ),

            // Mərkəz düymə: '0'
            _buildNumberKey('0'),

            // Sağ düymə: Backspace
            _buildSpecialKey(
              icon: Icons.backspace_outlined,
              isEnabled: _currentInput.isNotEmpty && !_verifyingPin,
              onTap: _onBackspaceTap,
              tooltip: 'Sil',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildNumberKey(d)).toList(),
    );
  }

  Widget _buildNumberKey(String number) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _verifyingPin ? null : () => _onDigitTap(number),
          splashColor: AppColors.base.withValues(alpha: 0.12),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isEnabled ? Colors.white : Colors.transparent,
        shape: const CircleBorder(),
        elevation: isEnabled ? 0.5 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isEnabled ? onTap : null,
          splashColor: AppColors.base.withValues(alpha: 0.12),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: isEnabled ? AppColors.base : const Color(0xFFD1D5DB),
            ),
          ),
        ),
      ),
    );
  }
}
