import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/models/send_register_code_request.dart';
import 'package:loyallig_flutter/features/auth/otp_verification_screen.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/auth/widgets/social_auth_section.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;

  String? _emailError;
  String? _firstNameError;
  String? _lastNameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _logDeviceInfo();
    _emailController.addListener(_clearError);
    _firstNameController.addListener(_clearError);
    _lastNameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _confirmPasswordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null ||
        _emailError != null ||
        _firstNameError != null ||
        _lastNameError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      setState(() {
        _errorMessage = null;
        _emailError = null;
        _firstNameError = null;
        _lastNameError = null;
        _passwordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _logDeviceInfo() async {
    final id = await DeviceHelper.getDeviceId();
    final name = await DeviceHelper.getDeviceName();
    debugPrint('==============================================');
    debugPrint('📱 [DEVICE INFO]');
    debugPrint('🆔 Device ID   : $id');
    debugPrint('📛 Device Name : $name');
    debugPrint('==============================================');
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _firstNameController.removeListener(_clearError);
    _lastNameController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _confirmPasswordController.removeListener(_clearError);

    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_loading || _googleLoading) return;

    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    String? emailErr;
    String? firstNameErr;
    String? lastNameErr;
    String? passErr;
    String? confirmPassErr;

    // E-poçt format yoxlanışı
    if (email.isEmpty) {
      emailErr = tr('auth_email_empty');
    } else if (!_isValidEmail(email)) {
      emailErr = tr('auth_email_invalid');
    }

    // Ad yoxlanışı
    if (firstName.isEmpty) {
      firstNameErr = tr('auth_first_name_empty');
    }

    // Soyad yoxlanışı
    if (lastName.isEmpty) {
      lastNameErr = tr('auth_last_name_empty');
    }

    // Şifrə: minimum 6 simvol, 1 böyük hərf, 1 rəqəm, 1 simvol yoxlanışı
    if (password.isEmpty) {
      passErr = tr('auth_password_empty');
    } else if (password.length < 6) {
      passErr = tr('auth_password_min');
    } else if (!RegExp(r'[A-Z]').hasMatch(password)) {
      passErr = tr('security_require_uppercase');
    } else if (!RegExp(r'[0-9]').hasMatch(password)) {
      passErr = tr('security_require_number');
    } else if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) {
      passErr = tr('security_require_special');
    }

    // Şifrənin təsdiqi yoxlanışı
    if (confirmPassword.isEmpty) {
      confirmPassErr = tr('security_confirm_empty');
    } else if (confirmPassword != password) {
      confirmPassErr = tr('auth_passwords_not_match');
    }

    // Əgər hər hansı bir xəta varsa, REQUEST GETMİR və border qırmızı olur!
    if (emailErr != null ||
        firstNameErr != null ||
        lastNameErr != null ||
        passErr != null ||
        confirmPassErr != null) {
      setState(() {
        _emailError = emailErr;
        _firstNameError = firstNameErr;
        _lastNameError = lastNameErr;
        _passwordError = passErr;
        _confirmPasswordError = confirmPassErr;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailError = null;
      _firstNameError = null;
      _lastNameError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    try {
      debugPrint('==============================================');
      debugPrint('🚀 [SEND REGISTER CODE GÖNDƏRİLİR]');
      debugPrint('📧 Email       : $email');
      debugPrint('👤 Ad Soyad    : $firstName $lastName');
      debugPrint('==============================================');

      final registerData = SendRegisterCodeRequest(
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        confirmPassword: confirmPassword,
      );

      await _authService.sendRegisterCode(registerData);

      if (!mounted) return;
      setState(() => _loading = false);

      // 200 OK gəldi -> 6 rəqəmli OTP səhifəsinə keçirik
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerificationScreen(registerData: registerData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = tr('auth_register_failed');
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = data['errorMessage']?.toString() ??
                data['message']?.toString() ??
                data['title']?.toString() ??
                tr('auth_register_failed');
          } else if (data is String) {
            errorMsg = data;
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = tr('auth_network_error');
        }
      }

      setState(() => _errorMessage = errorMsg);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading || _googleLoading) return;

    setState(() {
      _googleLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.signInWithGoogle();
      if (response == null) {
        // İstifadəçi pəncərəni bağladı
        if (mounted) setState(() => _googleLoading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _googleLoading = false);

      // Uğurla daxil oldu -> MainScreen-ə keçid
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _googleLoading = false);

      String errorMsg = tr('auth_google_auth_failed');
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = data['errorMessage']?.toString() ??
                data['message']?.toString() ??
                data['title']?.toString() ??
                errorMsg;
          } else if (data is String) {
            errorMsg = data;
          }
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          errorMsg = tr('auth_network_error');
        }
      } else if (e is Exception) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }

      setState(() => _errorMessage = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.text;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                tr('auth_register_title'),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 20),

              // E-poçt
              CustomInput(
                label: tr('auth_email_label'),
                hint: 'example@gmail.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                error: _emailError,
                marginBottom: 16,
              ),

              // Ad
              CustomInput(
                label: tr('auth_first_name_label'),
                hint: tr('auth_first_name_hint'),
                controller: _firstNameController,
                keyboardType: TextInputType.name,
                error: _firstNameError,
                marginBottom: 16,
              ),

              // Soyad
              CustomInput(
                label: tr('auth_last_name_label'),
                hint: tr('auth_last_name_hint'),
                controller: _lastNameController,
                keyboardType: TextInputType.name,
                error: _lastNameError,
                marginBottom: 16,
              ),

              // Yeni şifrə
              CustomInput(
                label: tr('auth_new_password_label'),
                hint: tr('auth_new_password_hint'),
                controller: _passwordController,
                isPassword: true,
                error: _passwordError,
                marginBottom: 16,
              ),

              // Şifrəni təkrarla
              CustomInput(
                label: tr('auth_confirm_password_label'),
                hint: tr('auth_confirm_password_hint'),
                controller: _confirmPasswordController,
                isPassword: true,
                error: _confirmPasswordError,
                marginBottom: 16,
              ),

              // Backend-dən gələn Xəta Mesajı bloku
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
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

              PrimaryButton(
                label: _loading ? tr('common_loading') : tr('auth_register_link'),
                onPressed: (_loading || _googleLoading) ? () {} : _handleRegister,
                height: 52,
                borderRadius: 12,
                paddingTop: 24,
              ),
              const SizedBox(height: 20),

              // divider & social buttons
              SocialAuthSection(
                onGoogleTap: (_loading || _googleLoading) ? null : _handleGoogleSignIn,
                isGoogleLoading: _googleLoading,
                dividerText: tr('auth_or_register'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('auth_have_account_text'),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: Text(
                      tr('auth_login_button'),
                      style: const TextStyle(
                        color: AppColors.base,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
