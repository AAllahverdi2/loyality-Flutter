import 'dart:io';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';

class BiometricSettingsScreen extends StatefulWidget {
  final bool showHeader;

  const BiometricSettingsScreen({
    super.key,
    this.showHeader = true,
  });

  @override
  State<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  bool _loading = true;
  bool _isSupported = false;
  bool _isEnabled = false;
  BiometricType? _primaryType;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final supported = await BiometricService.instance.isDeviceSupported();
    final canCheck = await BiometricService.instance.canCheckBiometrics();
    final enabled = await BiometricService.instance.isBiometricEnabled();
    final biometrics = await BiometricService.instance.getAvailableBiometrics();

    BiometricType? primaryType;
    if (biometrics.contains(BiometricType.face)) {
      primaryType = BiometricType.face;
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      primaryType = BiometricType.fingerprint;
    } else if (biometrics.contains(BiometricType.iris)) {
      primaryType = BiometricType.iris;
    }

    if (mounted) {
      setState(() {
        _isSupported = supported || canCheck;
        _isEnabled = enabled;
        _primaryType = primaryType;
        _loading = false;
      });
    }
  }

  String _getDisplayName() {
    if (_primaryType == BiometricType.face) {
      return 'Face ID';
    }
    if (_primaryType == BiometricType.fingerprint) {
      return Platform.isIOS ? 'Touch ID' : tr('biometric_type_fingerprint');
    }
    return tr('biometric_default_name');
  }

  Future<void> _toggleBiometric(bool value) async {
    final displayName = _getDisplayName();

    if (value) {
      final authResult = await BiometricService.instance.authenticate(
        localizedReason:
            tr('biometric_auth_reason', {'name': displayName}),
      );

      if (authResult.isSuccess) {
        await BiometricService.instance.setBiometricEnabled(true);
        if (mounted) {
          setState(() => _isEnabled = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr('biometric_auth_success', {'name': displayName}),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() => _isEnabled = false);
          if (authResult.status != BiometricAuthStatus.canceled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  authResult.errorMessage ?? tr('biometric_auth_failed'),
                ),
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } else {
      final displayName = _getDisplayName();
      await BiometricService.instance.setBiometricEnabled(false);
      if (mounted) {
        setState(() => _isEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('biometric_disabled', {'name': displayName}),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final cardBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);

    final displayName = _getDisplayName();

    final isFace = _primaryType == BiometricType.face;
    final biometricIcon =
        isFace ? Icons.face_rounded : Icons.fingerprint_rounded;

    final Widget mainBody = _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 28),

                // Hero Visual
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.base.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      biometricIcon,
                      size: 46,
                      color: AppColors.base,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  tr('biometric_desc', {'name': displayName}),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // Switch Setting Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          biometricIcon,
                          color: AppColors.base,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('biometric_switch_label', {'name': displayName}),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isEnabled
                                  ? tr('biometric_status_active')
                                  : tr('biometric_status_inactive'),
                              style: TextStyle(
                                fontSize: 13,
                                color: _isEnabled
                                    ? const Color(0xFF10B981)
                                    : secondaryTextColor,
                                fontWeight: _isEnabled
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isEnabled,
                        activeTrackColor: AppColors.base,
                        onChanged:
                            _isSupported ? _toggleBiometric : null,
                      ),
                    ],
                  ),
                ),

                if (!_isSupported) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr('biometric_not_supported_desc'),
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Privacy/Security Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF18181B).withValues(alpha: 0.5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security_rounded,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr('biometric_privacy_info'),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: secondaryTextColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );

    if (!widget.showHeader) {
      return mainBody;
    }

    return SwipeBackWrapper(
      enabled: widget.showHeader,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF171717) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF303030)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: textColor,
                          size: 26,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(child: mainBody),
            ],
          ),
        ),
      ),
    );
  }
}
