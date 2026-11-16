import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

enum _ChangeEmailStage {
  verifyCurrentEmail,
  enterNewEmail,
  confirmNewEmail,
}

class ChangeEmailScreen extends StatefulWidget {
  final String? currentEmail;

  const ChangeEmailScreen({
    this.currentEmail,
    super.key,
  });

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  static const int _initialCountdownSeconds = 300; // 5 dəqiqə = 300 saniyə

  final ProfileService _profileService = ProfileService();
  final TextEditingController _newEmailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  _ChangeEmailStage _stage = _ChangeEmailStage.verifyCurrentEmail;
  String _currentEmail = '';
  String? _verificationToken;
  String _newEmail = '';

  bool _hasSentCurrentCode = false;
  bool _loading = false;
  bool _resending = false;
  String? _errorMessage;
  String? _newEmailFieldError;

  Timer? _timer;
  int _secondsRemaining = _initialCountdownSeconds;

  @override
  void initState() {
    super.initState();
    _currentEmail =
        (widget.currentEmail ?? ProfileService.cachedProfile?.email ?? '')
            .trim();
    _newEmailController.addListener(_onNewEmailTextChanged);
    _initAndSendCurrentCode();
  }

  Future<void> _initAndSendCurrentCode() async {
    if (_currentEmail.isEmpty) {
      try {
        final profile = await _profileService.getMyProfile();
        if (mounted && profile?.email != null) {
          setState(() {
            _currentEmail = profile!.email!.trim();
          });
        }
      } catch (_) {}
    }
    await _sendCurrentCode(isInitial: true);
  }

  void _onNewEmailTextChanged() {
    if (_newEmailFieldError != null || _errorMessage != null) {
      setState(() {
        _newEmailFieldError = null;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newEmailController.removeListener(_onNewEmailTextChanged);
    _newEmailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _initialCountdownSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode => _otpControllers.map((c) => c.text.trim()).join();

  void _clearOtpBoxes({bool requestFirstFocus = true}) {
    for (final c in _otpControllers) {
      c.clear();
    }
    if (requestFirstFocus && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ADDIM 1: Cari Email-ə Təsdiq Kodunun Göndərilməsi
  // POST /api/Users/changeEmail/sendCurrentCode
  // ---------------------------------------------------------------------------
  Future<void> _sendCurrentCode({bool isInitial = false}) async {
    if (_loading || _resending) return;

    setState(() {
      if (isInitial || !_hasSentCurrentCode) {
        _loading = true;
      } else {
        _resending = true;
      }
      _errorMessage = null;
    });

    try {
      await _profileService.sendCurrentEmailCode();
      if (!mounted) return;

      setState(() {
        _hasSentCurrentCode = true;
        _loading = false;
        _resending = false;
        _errorMessage = null;
      });

      _clearOtpBoxes(requestFirstFocus: true);
      _startTimer();

      if (!isInitial) {
        _showSnackbar(tr('change_email_code_sent'));
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = ProfileService.extractErrorMessage(e);
      setState(() {
        _loading = false;
        _resending = false;
        _errorMessage = errMsg;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ADDIM 2: Cari Email-ə Gələn Kodun Təsdiqi (Token almaq)
  // POST /api/Users/changeEmail/verifyCurrentCode
  // ---------------------------------------------------------------------------
  Future<void> _handleVerifyCurrentCode() async {
    if (_loading) return;

    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = tr('change_email_otp_incomplete'));
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final token = await _profileService.verifyCurrentEmailCode(code);
      if (!mounted) return;

      _timer?.cancel();
      setState(() {
        _verificationToken = token;
        _loading = false;
        _errorMessage = null;
        _stage = _ChangeEmailStage.enterNewEmail;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = ProfileService.extractErrorMessage(e);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ADDIM 3: Yeni Email Ünvanına Kodun Göndərilməsi
  // POST /api/Users/changeEmail/sendNewCode
  // ---------------------------------------------------------------------------
  Future<void> _handleSendNewCode({bool isResend = false}) async {
    if (_loading || _resending) return;

    final targetEmail =
        isResend ? _newEmail : _newEmailController.text.trim();
    if (!isResend) {
      if (targetEmail.isEmpty) {
        setState(() => _newEmailFieldError = tr('change_email_empty_error'));
        return;
      }
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(targetEmail)) {
        setState(() => _newEmailFieldError = tr('change_email_invalid_error'));
        return;
      }
      if (_currentEmail.isNotEmpty &&
          targetEmail.toLowerCase() == _currentEmail.toLowerCase()) {
        setState(() => _newEmailFieldError = tr('change_email_same_error'));
        return;
      }
    }

    final token = _verificationToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _stage = _ChangeEmailStage.verifyCurrentEmail;
      });
      await _sendCurrentCode(isInitial: true);
      return;
    }

    setState(() {
      if (isResend) {
        _resending = true;
      } else {
        _loading = true;
      }
      _errorMessage = null;
      _newEmailFieldError = null;
    });

    try {
      await _profileService.sendNewEmailCode(
        token: token,
        newEmail: targetEmail,
      );
      if (!mounted) return;

      setState(() {
        _newEmail = targetEmail;
        _loading = false;
        _resending = false;
        _errorMessage = null;
        _stage = _ChangeEmailStage.confirmNewEmail;
      });

      _clearOtpBoxes(requestFirstFocus: true);
      _startTimer();

      if (isResend) {
        _showSnackbar(tr('change_email_code_sent'));
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = ProfileService.extractErrorMessage(e);
      setState(() {
        _loading = false;
        _resending = false;
        _errorMessage = errMsg;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ADDIM 4: Yeni Email-in Təsdiqi və Prosesin Tamamlanması
  // POST /api/Users/changeEmail/confirm
  // ---------------------------------------------------------------------------
  Future<void> _handleConfirmNewEmail() async {
    if (_loading) return;

    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = tr('change_email_otp_incomplete'));
      return;
    }

    final token = _verificationToken;
    if (token == null || token.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await _profileService.confirmChangeEmail(
        token: token,
        newEmail: _newEmail,
        code: code,
      );
      unawaited(
        _profileService
            .getMyProfile(forceRefresh: true)
            .catchError((_) => null),
      );

      if (!mounted) return;
      _timer?.cancel();
      setState(() => _loading = false);

      _showSnackbar(tr('change_email_success'));
      Navigator.of(context).pop(_newEmail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = ProfileService.extractErrorMessage(e);
      });
    }
  }

  void _applyPastedDigits(String rawText) {
    final digits = rawText.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    final count = digits.length > 6 ? 6 : digits.length;
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = i < count ? digits[i] : '';
    }

    if (count >= 6) {
      _otpFocusNodes[5].unfocus();
      if (_stage == _ChangeEmailStage.verifyCurrentEmail) {
        _handleVerifyCurrentCode();
      } else if (_stage == _ChangeEmailStage.confirmNewEmail) {
        _handleConfirmNewEmail();
      }
    } else {
      _otpFocusNodes[count].requestFocus();
      _otpControllers[count].selection = TextSelection.collapsed(
        offset: _otpControllers[count].text.length,
      );
    }
  }

  Future<void> _handleClipboardPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty || !mounted) return;
    _applyPastedDigits(text);
  }

  void _onDigitChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    // İstifadəçi bütöv kodu yapışdırdıqda (Paste) və ya xanada artıq rəqəm olduqda
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length > 2) {
        final cleanDigits =
            digits.length > 6 ? digits.substring(digits.length - 6) : digits;
        _applyPastedDigits(cleanDigits);
        return;
      }

      final lastDigit = digits.isNotEmpty ? digits[digits.length - 1] : '';
      _otpControllers[index].text = lastDigit;
      _otpControllers[index].selection =
          TextSelection.collapsed(offset: lastDigit.length);
      if (lastDigit.isNotEmpty) {
        if (index < 5) {
          _otpFocusNodes[index + 1].requestFocus();
        } else {
          _otpFocusNodes[index].unfocus();
          if (_otpCode.length == 6) {
            if (_stage == _ChangeEmailStage.verifyCurrentEmail) {
              _handleVerifyCurrentCode();
            } else if (_stage == _ChangeEmailStage.confirmNewEmail) {
              _handleConfirmNewEmail();
            }
          }
        }
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        if (_otpCode.length == 6) {
          if (_stage == _ChangeEmailStage.verifyCurrentEmail) {
            _handleVerifyCurrentCode();
          } else if (_stage == _ChangeEmailStage.confirmNewEmail) {
            _handleConfirmNewEmail();
          }
        }
      }
    } else if (index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpControllers[index].text.isEmpty && index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
        _otpControllers[index - 1].clear();
      }
    }
  }

  int get _activeStepIndex => switch (_stage) {
        _ChangeEmailStage.verifyCurrentEmail => 0,
        _ChangeEmailStage.enterNewEmail => 1,
        _ChangeEmailStage.confirmNewEmail => 2,
      };

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

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_stage == _ChangeEmailStage.confirmNewEmail &&
                            !_loading) {
                          setState(() {
                            _errorMessage = null;
                            _stage = _ChangeEmailStage.enterNewEmail;
                          });
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF171717) : Colors.white,
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
                          tr('change_email_title'),
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

              // Stepper Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildStepper(
                  isDark: isDark,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),

              // Body Content
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: switch (_stage) {
                    _ChangeEmailStage.verifyCurrentEmail =>
                      _buildVerifyCurrentStage(
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                    _ChangeEmailStage.enterNewEmail => _buildEnterNewEmailStage(
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                    _ChangeEmailStage.confirmNewEmail =>
                      _buildConfirmNewEmailStage(
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        borderColor: borderColor,
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper({
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final labels = [
      tr('change_email_step1_short'),
      tr('change_email_step2_short'),
      tr('change_email_step3_short'),
    ];

    return Row(
      children: List.generate(3, (index) {
        final isCompleted = index < _activeStepIndex;
        final isCurrent = index == _activeStepIndex;
        final activeColor = isCompleted
            ? const Color(0xFF10B981)
            : (isCurrent
                ? AppColors.base
                : (isDark
                    ? const Color(0xFF27272A)
                    : const Color(0xFFE5E7EB)));

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (isCompleted) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        '${index + 1}. ${labels[index]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isCurrent || isCompleted
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isCurrent
                              ? textColor
                              : (isCompleted
                                  ? const Color(0xFF10B981)
                                  : secondaryTextColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerifyCurrentStage({
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    if (!_hasSentCurrentCode && _loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.base),
            const SizedBox(height: 20),
            Text(
              tr('change_email_sending_current'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: secondaryTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSentCurrentCode && _errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 32),
        child: Column(
          children: [
            _buildStageHeaderIcon(Icons.mark_email_unread_rounded),
            const SizedBox(height: 16),
            Text(
              tr('change_email_step1_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: 16),
            PrimaryButton(
              label: tr('change_email_send_code_btn'),
              onPressed: () => _sendCurrentCode(isInitial: true),
              height: 52,
              borderRadius: 14,
            ),
          ],
        ),
      );
    }

    final isTimerActive = _secondsRemaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _buildStageHeaderIcon(Icons.mark_email_read_outlined),
        const SizedBox(height: 16),
        Text(
          tr('change_email_step1_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('change_email_step1_desc'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            height: 1.45,
          ),
        ),
        if (_currentEmail.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildEmailPill(
            email: _currentEmail,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
          ),
        ],
        const SizedBox(height: 28),
        _buildOtpBoxes(isDark: isDark, textColor: textColor),
        const SizedBox(height: 20),
        if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
          _buildErrorBanner(_errorMessage!),
        _buildTimerAndResend(
          isTimerActive: isTimerActive,
          onResend: () => _sendCurrentCode(isInitial: false),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: _loading ? tr('pin_code_verifying') : tr('verify_button'),
          onPressed: _loading ? () {} : _handleVerifyCurrentCode,
          height: 52,
          borderRadius: 14,
        ),
      ],
    );
  }

  Widget _buildEnterNewEmailStage({
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _buildStageHeaderIcon(Icons.alternate_email_rounded),
        const SizedBox(height: 16),
        Text(
          tr('change_email_step2_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('change_email_step2_desc'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
        CustomInput(
          label: tr('change_email_new_label'),
          controller: _newEmailController,
          hint: tr('change_email_new_hint'),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: true,
          error: _newEmailFieldError,
          rightIcon: Icons.email_outlined,
          onSubmitted: (_) => _handleSendNewCode(isResend: false),
          marginBottom: 16,
        ),
        if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
          _buildErrorBanner(_errorMessage!),
        const SizedBox(height: 16),
        PrimaryButton(
          label: _loading
              ? tr('change_email_sending')
              : tr('change_email_send_code_btn'),
          onPressed:
              _loading ? () {} : () => _handleSendNewCode(isResend: false),
          height: 52,
          borderRadius: 14,
        ),
      ],
    );
  }

  Widget _buildConfirmNewEmailStage({
    required bool isDark,
    required Color cardBg,
    required Color textColor,
    required Color secondaryTextColor,
    required Color borderColor,
  }) {
    final isTimerActive = _secondsRemaining > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        _buildStageHeaderIcon(Icons.verified_user_outlined),
        const SizedBox(height: 16),
        Text(
          tr('change_email_step3_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('change_email_step3_desc'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        _buildEmailPill(
          email: _newEmail,
          cardBg: cardBg,
          borderColor: borderColor,
          textColor: textColor,
          onEditTap: _loading
              ? null
              : () {
                  setState(() {
                    _errorMessage = null;
                    _stage = _ChangeEmailStage.enterNewEmail;
                  });
                },
        ),
        const SizedBox(height: 28),
        _buildOtpBoxes(isDark: isDark, textColor: textColor),
        const SizedBox(height: 20),
        if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
          _buildErrorBanner(_errorMessage!),
        _buildTimerAndResend(
          isTimerActive: isTimerActive,
          onResend: () => _handleSendNewCode(isResend: true),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: _loading
              ? tr('pin_code_verifying')
              : tr('change_email_confirm_btn'),
          onPressed: _loading ? () {} : _handleConfirmNewEmail,
          height: 52,
          borderRadius: 14,
        ),
      ],
    );
  }

  Widget _buildStageHeaderIcon(IconData icon) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: AppColors.base,
        size: 32,
      ),
    );
  }

  Widget _buildEmailPill({
    required String email,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    VoidCallback? onEditTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.email_outlined,
            size: 16,
            color: AppColors.base,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onEditTap != null) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onEditTap,
              child: Text(
                tr('change_email_edit_new'),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.base,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtpBoxes({
    required bool isDark,
    required Color textColor,
  }) {
    final hasError = _errorMessage != null && _errorMessage!.trim().isNotEmpty;
    return Actions(
      actions: <Type, Action<Intent>>{
        PasteTextIntent: CallbackAction<PasteTextIntent>(
          onInvoke: (intent) {
            _handleClipboardPaste();
            return null;
          },
        ),
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return SizedBox(
            width: 48,
            height: 56,
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) => _onKeyDown(index, event),
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                cursorColor: AppColors.base,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  fillColor: isDark
                      ? AppColors.darkInputBackground
                      : AppColors.inputBackground,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasError
                          ? AppColors.error
                          : (isDark ? AppColors.darkBorder : AppColors.border),
                      width: hasError ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: hasError ? AppColors.error : AppColors.base,
                      width: 1.8,
                    ),
                  ),
                ),
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline,
              color: Color(0xFFDC2626),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerAndResend({
    required bool isTimerActive,
    required VoidCallback onResend,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: isTimerActive ? AppColors.base : AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              _formattedTime,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isTimerActive ? AppColors.base : AppColors.secondaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: (isTimerActive || _resending) ? null : onResend,
          child: Text(
            _resending
                ? tr('change_email_sending')
                : (isTimerActive
                    ? tr('change_email_wait_timer')
                    : tr('change_email_resend')),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isTimerActive ? AppColors.secondaryText : AppColors.base,
              decoration: isTimerActive
                  ? TextDecoration.none
                  : TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
