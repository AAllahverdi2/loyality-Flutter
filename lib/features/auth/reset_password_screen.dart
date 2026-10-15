import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/models/forgot_password_request.dart';
import 'package:loyallig_flutter/features/auth/models/reset_password_request.dart';
import 'package:loyallig_flutter/features/auth/models/verify_reset_code_request.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    required this.email,
    super.key,
  });

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _initialCountdownSeconds = 300; // 5 dəqiqə

  final List<TextEditingController> _codeControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes = List.generate(6, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  Timer? _timer;
  int _secondsRemaining = _initialCountdownSeconds;
  bool _loading = false;
  bool _resending = false;

  /// verifyResetCode uğurlu olduqda backend-dən qayıdan resetToken
  String? _resetToken;

  String? _codeError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _newPasswordController.addListener(_clearErrors);
    _confirmPasswordController.addListener(_clearErrors);

    for (int i = 0; i < 6; i++) {
      final index = i;
      _codeFocusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_codeControllers[index].text.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
            _codeControllers[index - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _initialCountdownSeconds);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _clearErrors() {
    if (_passwordError != null ||
        _confirmPasswordError != null ||
        _errorMessage != null) {
      setState(() {
        _passwordError = null;
        _confirmPasswordError = null;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    _newPasswordController.removeListener(_clearErrors);
    _confirmPasswordController.removeListener(_clearErrors);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode {
    return _codeControllers.map((c) => c.text.trim()).join();
  }

  void _onDigitChanged(int index, String value) {
    if (_codeError != null || _errorMessage != null) {
      setState(() {
        _codeError = null;
        _errorMessage = null;
      });
    }

    // Əgər istifadəçi bütöv kodu yapışdırarsa (Paste) və ya xanada artıq rəqəm varsa
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 6) {
        for (int i = 0; i < 6; i++) {
          _codeControllers[i].text = digits[i];
        }
        _codeFocusNodes[5].unfocus();
        _handleVerifyCode();
        return;
      }

      // Xana dolu olduqda yeni rəqəm yazıldıqda sonuncu daxil ediləni saxlayırıq
      final lastDigit = digits.isNotEmpty ? digits[digits.length - 1] : '';
      _codeControllers[index].text = lastDigit;
      _codeControllers[index].selection =
          TextSelection.collapsed(offset: lastDigit.length);
      if (lastDigit.isNotEmpty && index < 5) {
        _codeFocusNodes[index + 1].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _codeFocusNodes[index + 1].requestFocus();
      } else {
        _codeFocusNodes[index].unfocus();
        // 6 rəqəm tamamlanan kimi avtomatik təsdiqləməyə göndər
        if (_otpCode.length == 6) {
          _handleVerifyCode();
        }
      }
    } else {
      if (index > 0) {
        _codeFocusNodes[index - 1].requestFocus();
      }
    }
  }

  /// Kodu yenidən göndər
  Future<void> _handleResendCode() async {
    if (_resending || _secondsRemaining > 0) return;

    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      await _authService.forgotPassword(
        ForgotPasswordRequest(email: widget.email),
      );

      if (!mounted) return;
      setState(() {
        _resending = false;
      });

      for (final c in _codeControllers) {
        c.clear();
      }
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni təsdiq kodu e-poçtunuza göndərildi.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _errorMessage = 'Kodu yenidən göndərmək mümkün olmadı.';
      });
    }
  }

  /// Step 2: 6 rəqəmli OTP kodunu yoxla (/api/Auth/verifyResetCode)
  Future<void> _handleVerifyCode() async {
    if (_loading) return;

    final code = _otpCode;
    if (code.isEmpty) {
      setState(() => _codeError = 'Təsdiq kodunu daxil edin.');
      return;
    } else if (code.length < 6) {
      setState(() => _codeError = '6 rəqəmli təsdiq kodunu tam daxil edin.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _codeError = null;
    });

    try {
      final response = await _authService.verifyResetCode(
        VerifyResetCodeRequest(
          email: widget.email,
          code: code,
        ),
      );

      final data = response.data;
      final isSuccess = data is Map
          ? (data['isSuccess'] == true)
          : (response.statusCode == 200 || response.statusCode == 201);

      String? token;
      if (data is Map) {
        if (data['result'] is Map) {
          token = data['result']['resetToken']?.toString();
        } else if (data['result'] is String) {
          token = data['result']?.toString();
        } else if (data['resetToken'] != null) {
          token = data['resetToken']?.toString();
        }
      }

      if (!mounted) return;
      setState(() => _loading = false);

      if (isSuccess && token != null && token.isNotEmpty) {
        setState(() {
          _resetToken = token;
          _errorMessage = null;
          _codeError = null;
        });
      } else {
        setState(() {
          _errorMessage = data is Map
              ? (data['errorMessage']?.toString() ??
                  'Təsdiq kodu yanlışdır və ya vaxtı bitib.')
              : 'Təsdiq kodu yanlışdır və ya vaxtı bitib.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = 'Təsdiq kodunu yoxlamaq mümkün olmadı.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['errorMessage']?.toString() ??
              data['message']?.toString() ??
              data['title']?.toString() ??
              errorMsg;
        } else if (data is String) {
          errorMsg = data;
        }
      }
      setState(() => _errorMessage = errorMsg);
    }
  }

  /// Step 3: Yeni şifrəni təyin et (/api/Auth/resetPassword)
  Future<void> _handleResetPassword() async {
    if (_loading) return;

    if (_resetToken == null) {
      setState(() {
        _errorMessage = 'Sessiya vaxtı bitib. Zəhmət olmasa kodu yenidən daxil edin.';
      });
      return;
    }

    final password = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    String? passErr;
    String? confirmErr;

    // Şifrə: minimum 6 simvol, 1 böyük hərf, 1 rəqəm, 1 simvol yoxlanışı
    if (password.isEmpty) {
      passErr = 'Yeni şifrə daxil edin.';
    } else if (password.length < 6) {
      passErr = 'Şifrə minimum 6 simvoldan ibarət olmalıdır.';
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passErr = 'Şifrədə ən azı 1 böyük hərf (A-Z) olmalıdır.';
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      passErr = 'Şifrədə ən azı 1 rəqəm (0-9) olmalıdır.';
    } else if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      passErr = 'Şifrədə ən azı 1 xüsusi simvol (@, #, !, %, & və s.) olmalıdır.';
    }

    // Şifrə təsdiqi yoxlanışı
    if (confirmPassword.isEmpty) {
      confirmErr = 'Şifrəni təkrar daxil edin.';
    } else if (password != confirmPassword) {
      confirmErr = 'Şifrələr eyni deyil.';
    }

    if (passErr != null || confirmErr != null) {
      setState(() {
        _passwordError = passErr;
        _confirmPasswordError = confirmErr;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    try {
      final response = await _authService.resetPassword(
        ResetPasswordRequest(
          resetToken: _resetToken!,
          newPassword: password,
          confirmNewPassword: confirmPassword,
        ),
      );

      final data = response.data;
      final isSuccess = data is Map
          ? (data['isSuccess'] == true)
          : (response.statusCode == 200 || response.statusCode == 204);

      if (!mounted) return;
      setState(() => _loading = false);

      if (isSuccess) {
        // Uğurla dəyişdirildi -> LoginScreen-ə yönləndiririk
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Şifrəniz uğurla yeniləndi! Yeni şifrənizlə daxil olun.'),
            backgroundColor: Color(0xFF16A34A),
            duration: Duration(seconds: 4),
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage =
              data['errorMessage']?.toString() ?? 'Şifrəni yeniləmək mümkün olmadı.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = 'Şifrəni yeniləmək mümkün olmadı.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['errorMessage']?.toString() ??
              data['message']?.toString() ??
              data['title']?.toString() ??
              errorMsg;
        } else if (data is String) {
          errorMsg = data;
        }
      }
      setState(() => _errorMessage = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final isOtpStep = _resetToken == null;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Geri düyməsi
              GestureDetector(
                onTap: () {
                  if (!isOtpStep) {
                    // Əgər yeni şifrə mərhələsindədirsə, təsdiq kodu mərhələsinə qayıt
                    setState(() {
                      _resetToken = null;
                      _errorMessage = null;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
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
                    color: isDark ? Colors.white : Colors.black,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Başlıq
              Text(
                isOtpStep ? 'Təsdiq kodu' : 'Yeni şifrə',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),

              // Açıqlama
              Text(
                isOtpStep
                    ? '${widget.email} ünvanına göndərilən 6 rəqəmli təsdiq kodunu daxil edin.'
                    : 'Hesabınız üçün yeni şifrə təyin edin.',
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // ==========================================
              // ADDIM 1: YALNIZ OTP KODU VƏ TƏSDİQLƏNMƏSİ
              // ==========================================
              if (isOtpStep) ...[
                // Təsdiq kodu etiketi
                Text(
                  'Təsdiq kodu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),

                // 6 Rəqəmli OTP Kod Qutuları
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final hasError =
                        _codeError != null || _errorMessage != null;
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _codeControllers[index],
                        focusNode: _codeFocusNodes[index],
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
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          fillColor: isDark
                              ? const Color(0xFF18181B)
                              : const Color(0xFFF9FAFB),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: hasError
                                  ? const Color(0xFFEF4444)
                                  : isDark
                                      ? const Color(0xFF27272A)
                                      : const Color(0xFFE5E7EB),
                              width: hasError ? 1.5 : 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: hasError
                                  ? const Color(0xFFEF4444)
                                  : AppColors.base,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    );
                  }),
                ),

                if (_codeError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _codeError!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Taymer və Yenidən göndər
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formattedTime,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _secondsRemaining == 0 && !_resending
                          ? _handleResendCode
                          : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _resending ? 'Göndərilir...' : 'Kodu yenidən göndər',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondsRemaining == 0 && !_resending
                              ? AppColors.base
                              : AppColors.secondaryText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ==========================================
              // ADDIM 2: YALNIZ YENİ ŞİFRƏ VƏ TƏSDİQİ
              // (Yalnız 200 OK gəldikdən sonra görünür)
              // ==========================================
              if (!isOtpStep) ...[
                CustomInput(
                  label: 'Yeni şifrə',
                  hint: 'Yeni şifrənizi daxil edin',
                  controller: _newPasswordController,
                  isPassword: true,
                  error: _passwordError,
                  marginBottom: 16,
                ),

                CustomInput(
                  label: 'Şifrəni təsdiqlə',
                  hint: 'Şifrəni təkrar daxil edin',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  error: _confirmPasswordError,
                  marginBottom: 16,
                ),
              ],

              // Xəta Mesajı (Backend-dən gələn)
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
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

              const SizedBox(height: 8),

              // Əsas Düymə
              // isOtpStep == true -> "Kodu təsdiqlə" (verifyResetCode çağırır)
              // isOtpStep == false -> "Şifrəni yenilə" (resetPassword çağırır)
              PrimaryButton(
                label: isOtpStep
                    ? (_loading ? 'Yoxlanılır...' : 'Kodu təsdiqlə')
                    : (_loading ? 'Yenilənir...' : 'Şifrəni yenilə'),
                onPressed: _loading
                    ? () {}
                    : (isOtpStep ? _handleVerifyCode : _handleResetPassword),
                height: 52,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
