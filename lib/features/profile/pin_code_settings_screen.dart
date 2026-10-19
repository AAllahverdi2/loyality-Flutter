import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/services/pin_code_service.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';

class PinCodeSettingsScreen extends StatefulWidget {
  final bool showHeader;
  final bool isMandatorySetup;

  const PinCodeSettingsScreen({
    super.key,
    this.showHeader = true,
    this.isMandatorySetup = false,
  });

  @override
  State<PinCodeSettingsScreen> createState() => _PinCodeSettingsScreenState();
}

class _PinCodeSettingsScreenState extends State<PinCodeSettingsScreen> {
  bool _loading = true;
  bool _hasExistingPin = false;

  // Rejimlər: 'view' (status göstərir), 'enter_new' (yeni PIN), 'confirm_new' (təsdiq)
  String _mode = 'view';
  String _firstPin = '';
  String _currentInput = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  Future<void> _checkExistingPin() async {
    if (widget.isMandatorySetup) {
      if (mounted) {
        setState(() {
          _hasExistingPin = false;
          _mode = 'enter_new';
          _loading = false;
        });
      }
      return;
    }
    final hasPin = await TokenStorage.hasPinCode();
    if (mounted) {
      setState(() {
        _hasExistingPin = hasPin;
        _mode = hasPin ? 'view' : 'enter_new';
        _loading = false;
      });
    }
  }

  void _onNumberTap(String number) {
    if (_currentInput.length >= 4) return;

    setState(() {
      _currentInput += number;
      _errorMessage = null;
    });

    if (_currentInput.length == 4) {
      _handleFourDigitsEntered();
    }
  }

  void _onBackspaceTap() {
    if (_currentInput.isEmpty) return;
    setState(() {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _handleFourDigitsEntered() async {
    if (_mode == 'enter_new') {
      _firstPin = _currentInput;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        _mode = 'confirm_new';
        _currentInput = '';
        _errorMessage = null;
      });
    } else if (_mode == 'confirm_new') {
      if (_currentInput == _firstPin) {
        setState(() => _loading = true);
        try {
          await PinCodeService.instance.setPinCode(
            pinCode: _firstPin,
            confirmPinCode: _currentInput,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('pin_code_success_set')),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (widget.isMandatorySetup) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const MainScreen()),
              (route) => false,
            );
          } else if (widget.showHeader) {
            Navigator.of(context).pop(true);
          } else {
            setState(() {
              _hasExistingPin = true;
              _mode = 'view';
              _currentInput = '';
              _firstPin = '';
              _errorMessage = null;
              _loading = false;
            });
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _errorMessage = e.toString().replaceFirst('Exception: ', '');
            _currentInput = '';
            _firstPin = '';
            _mode = 'enter_new';
          });
        }
      } else {
        setState(() {
          _errorMessage = tr('pin_code_mismatch');
          _currentInput = '';
          _mode = 'enter_new';
          _firstPin = '';
        });
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

    final Widget bodyContent;
    if (_loading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (_mode == 'view') {
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 36),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 46,
                color: AppColors.base,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('pin_code_status_set'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('pin_code_status_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 36),

            // Dəyişdir kartı
            Material(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _mode = 'enter_new';
                    _currentInput = '';
                    _firstPin = '';
                    _errorMessage = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF27272A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.base,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('pin_code_change_button'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('pin_code_change_desc'),
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          const SizedBox(height: 28),
          Text(
            _mode == 'confirm_new'
                ? tr('pin_code_confirm_title')
                : tr('pin_code_enter_new_title'),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == 'confirm_new'
                ? tr('pin_code_confirm_desc')
                : tr('pin_code_enter_new_desc'),
            style: TextStyle(
              fontSize: 13.5,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(height: 32),

          // 4 Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final filled = index < _currentInput.length;
              return Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? AppColors.base
                      : (isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE5E7EB)),
                  border: Border.all(
                    color: filled
                        ? AppColors.base
                        : (isDark
                            ? const Color(0xFF3F3F46)
                            : const Color(0xFFD1D5DB)),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const Spacer(),

          // Numeric Keypad
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildKeypadRow(['1', '2', '3'], textColor, isDark),
                const SizedBox(height: 16),
                _buildKeypadRow(['4', '5', '6'], textColor, isDark),
                const SizedBox(height: 16),
                _buildKeypadRow(['7', '8', '9'], textColor, isDark),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (_hasExistingPin)
                      _buildKeypadIconButton(
                        Icons.close_rounded,
                        secondaryTextColor,
                        isDark,
                        () {
                          setState(() {
                            _mode = 'view';
                            _currentInput = '';
                            _firstPin = '';
                            _errorMessage = null;
                          });
                        },
                      )
                    else
                      const SizedBox(width: 72, height: 72),
                    _buildKeypadButton('0', textColor, isDark, () {
                      _onNumberTap('0');
                    }),
                    _buildKeypadIconButton(
                      Icons.backspace_outlined,
                      textColor,
                      isDark,
                      _onBackspaceTap,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),
        ],
      );
    }

    final canPop = !widget.isMandatorySetup;

    Widget fullContent;
    if (!widget.showHeader && !widget.isMandatorySetup) {
      fullContent = bodyContent;
    } else {
      fullContent = Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    if (!widget.isMandatorySetup)
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
                      )
                    else
                      const SizedBox(width: 44),
                    Expanded(
                      child: Center(
                        child: Text(
                          tr('pin_code_title'),
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
              Expanded(child: bodyContent),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: canPop,
      child: SwipeBackWrapper(
        enabled: canPop && widget.showHeader,
        child: fullContent,
      ),
    );
  }

  Widget _buildKeypadRow(
      List<String> numbers, Color textColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) {
        return _buildKeypadButton(n, textColor, isDark, () {
          _onNumberTap(n);
        });
      }).toList(),
    );
  }

  Widget _buildKeypadButton(
      String label, Color textColor, bool isDark, VoidCallback onTap) {
    return Material(
      color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadIconButton(
      IconData icon, Color textColor, bool isDark, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: Icon(
              icon,
              size: 26,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
