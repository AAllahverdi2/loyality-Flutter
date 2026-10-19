import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/features/auth/models/register_request.dart';
import 'package:loyallig_flutter/features/auth/models/send_register_code_request.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';
import 'package:loyallig_flutter/features/profile/pin_code_settings_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.registerData,
    super.key,
  });

  final SendRegisterCodeRequest registerData;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _initialCountdownSeconds = 300; // 5 dəqiqə = 300 saniyə

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();
  Timer? _timer;
  int _secondsRemaining = _initialCountdownSeconds;
  bool _loading = false;
  bool _resending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _otpCode {
    return _controllers.map((c) => c.text.trim()).join();
  }

  void _onDigitChanged(int index, String value) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // 6 rəqəm tamamlanan kimi avtomatik təsdiqləməyə göndər
        if (_otpCode.length == 6) {
          _handleVerify();
        }
      }
    } else {
      // İstifadəçi rəqəmi sildikdə (backspace) əvvəlki qutuya qayıt
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _onKeyDown(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpCode;
    if (code.length < 6) {
      setState(() => _errorMessage = '6 rəqəmli təsdiq kodunu daxil edin.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();

      debugPrint('==============================================');
      debugPrint('🔑 [POST /api/Auth/register GÖNDƏRİLİR]');
      debugPrint('📧 Email       : ${widget.registerData.email}');
      debugPrint('👤 Ad Soyad    : ${widget.registerData.firstName} ${widget.registerData.lastName}');
      debugPrint('🔢 OtpCode     : $code');
      debugPrint('🆔 Device ID   : $deviceId');
      debugPrint('📛 Device Name : $deviceName');
      debugPrint('==============================================');

      // Təsdiq kodu və qeydiyyat məlumatları birbaşa /api/Auth/register-ə göndərilir
      await _authService.register(
        RegisterRequest(
          email: widget.registerData.email,
          password: widget.registerData.password,
          confirmPassword: widget.registerData.confirmPassword,
          firstName: widget.registerData.firstName,
          lastName: widget.registerData.lastName,
          otpCode: code,
          deviceId: deviceId,
          deviceName: deviceName,
        ),
      );

      if (!mounted) return;
      setState(() => _loading = false);

      final hasPin = await TokenStorage.hasPinCode();
      if (!mounted) return;

      if (hasPin) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const PinCodeSettingsScreen(
              showHeader: false,
              isMandatorySetup: true,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = 'Təsdiqləmə zamanı xəta baş verdi.';
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map) {
            final rawError = data['errorMessage']?.toString() ??
                data['message']?.toString() ??
                data['title']?.toString();
            if (rawError != null && rawError.trim().isNotEmpty) {
              errorMsg = rawError.trim();
            }

            // Backend validation errors (məsələn: { errors: { ... } } və ya { errors: [ ... ] })
            if (data['errors'] != null) {
              final errors = data['errors'];
              if (errors is List && errors.isNotEmpty) {
                errorMsg = errors.join('\n');
              } else if (errors is Map && errors.isNotEmpty) {
                final messages = <String>[];
                for (final val in errors.values) {
                  if (val is List) {
                    messages.addAll(val.map((item) => item.toString()));
                  } else {
                    messages.add(val.toString());
                  }
                }
                if (messages.isNotEmpty) {
                  errorMsg = messages.join('\n');
                }
              }
            }
          } else if (data is String && data.trim().isNotEmpty) {
            errorMsg = data.trim();
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = 'Serverlə əlaqə qurula bilmədi (Şəbəkə xətası).';
        }
      }

      if (errorMsg.trim().isEmpty) {
        errorMsg = 'Kod yanlışdır və ya xəta baş verdi.';
      }

      setState(() => _errorMessage = errorMsg);
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0 || _resending) return;

    setState(() {
      _resending = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔄 [KOD YENİDƏN GÖNDƏRİLİR: /api/Auth/sendRegisterCode]');
      await _authService.sendRegisterCode(widget.registerData);

      if (!mounted) return;
      setState(() => _resending = false);

      // Qutuları təmizləyirik və taymeri yenidən 5 dəqiqəyə başlayırıq
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeni təsdiq kodu e-poçtunuza göndərildi.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);

      String errorMsg = 'Kodu yenidən göndərərkən xəta baş verdi.';
      if (e is DioException && e.response?.data is Map) {
        errorMsg = e.response?.data['errorMessage']?.toString() ?? errorMsg;
      }
      setState(() => _errorMessage = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final isTimerActive = _secondsRemaining > 0;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Başlıq
              Text(
                'Təsdiq Kodu',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),

              // Açıqlama
              Text(
                '6 rəqəmli təsdiq kodu bu e-poçt ünvanına göndərildi:\n${widget.registerData.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // 6 Qutulu OTP Girişi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasError = _errorMessage != null;
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _onKeyDown(index, event),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
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
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border),
                              width: hasError ? 1.5 : 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: hasError
                                  ? AppColors.error
                                  : AppColors.base,
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
              const SizedBox(height: 24),

              // Xəta mesajı bloku (Mesaj tam və aydın görünür)
              if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.error_outline,
                            color: Color(0xFFDC2626), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 5 Dəqiqəlik Taymer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: isTimerActive
                        ? AppColors.base
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isTimerActive
                          ? AppColors.base
                          : AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Kodu yenidən göndər düyməsi / linki
              GestureDetector(
                onTap: isTimerActive ? null : _handleResend,
                child: Text(
                  _resending
                      ? 'Göndərilir...'
                      : (isTimerActive
                          ? 'Kodu yenidən göndərmək üçün taymeri gözləyin'
                          : 'Kodu yenidən göndər'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isTimerActive
                        ? AppColors.secondaryText
                        : AppColors.base,
                    decoration: isTimerActive
                        ? TextDecoration.none
                        : TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Təsdiqlə Düyməsi
              PrimaryButton(
                label: _loading ? 'Yoxlanılır...' : 'Təsdiq et',
                onPressed: _loading ? () {} : _handleVerify,
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
