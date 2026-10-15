import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';

class BiometricPromptSheet extends StatefulWidget {
  const BiometricPromptSheet({
    required this.biometricName,
    super.key,
  });

  final String biometricName;

  static Future<void> showIfEligible(BuildContext context) async {
    try {
      final biometricService = BiometricService.instance;
      final isSupported = await biometricService.isDeviceSupported();
      final canCheck = await biometricService.canCheckBiometrics();
      final isEnabled = await biometricService.isBiometricEnabled();
      final hasPrompted = await biometricService.hasPromptedBiometric();

      debugPrint('==================================================');
      debugPrint('🔍 [BIOMETRIC PROMPT CHECK]:');
      debugPrint('   isDeviceSupported  : $isSupported');
      debugPrint('   canCheckBiometrics : $canCheck');
      debugPrint('   isBiometricEnabled : $isEnabled');
      debugPrint('   hasPrompted        : $hasPrompted');
      debugPrint('==================================================');

      if (!isSupported && !canCheck) {
        debugPrint('⚠️ [BiometricPromptSheet] Cihaz biometrika dəstəkləmir.');
        return;
      }

      if (isEnabled) {
        debugPrint('ℹ️ [BiometricPromptSheet] Biometrika artıq aktivdir.');
        return;
      }

      if (hasPrompted) {
        debugPrint('ℹ️ [BiometricPromptSheet] Artıq sorğu verilib.');
        return;
      }

      final biometricName = await biometricService.getBiometricDisplayName();

      if (!context.mounted) return;

      final enabled = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BiometricPromptSheet(biometricName: biometricName),
      );

      // İstifadəçiyə artıq sorğu verildiyini qeyd edirik
      await biometricService.setPromptedBiometric(true);

      if (context.mounted && enabled == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('biometric_enabled_msg')),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('🚨 [BiometricPromptSheet XƏTASI]: $e\n$stack');
    }
  }

  @override
  State<BiometricPromptSheet> createState() => _BiometricPromptSheetState();
}

class _BiometricPromptSheetState extends State<BiometricPromptSheet> {
  bool _loading = false;
  String? _errorMessage;

  Future<void> _handleEnable() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final result = await BiometricService.instance.authenticate(
      localizedReason: tr('biometric_reason'),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      await BiometricService.instance.setBiometricEnabled(true);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
          _errorMessage = result.errorMessage;
        }
      });
    }
  }

  void _handleSkip() {
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final isFace = widget.biometricName.toLowerCase().contains('face');

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Biometric Icon Container
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFC91C1C).withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFC91C1C).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              isFace ? Icons.face_rounded : Icons.fingerprint_rounded,
              color: const Color(0xFFC91C1C),
              size: 42,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            tr('biometric_enable_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              tr('biometric_enable_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: secondaryTextColor,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          const SizedBox(height: 28),

          // Primary Enable Button
          PrimaryButton(
            label: _loading
                ? tr('common_loading')
                : '${tr('biometric_enable_btn')} (${widget.biometricName})',
            onPressed: _loading ? () {} : _handleEnable,
            height: 52,
            borderRadius: 14,
          ),
          const SizedBox(height: 12),

          // Skip Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _loading ? null : _handleSkip,
              child: Text(
                tr('biometric_not_now'),
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
