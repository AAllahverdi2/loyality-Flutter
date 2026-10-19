import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/utils/device_helper.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/features/auth/forgot_password_screen.dart';
import 'package:loyallig_flutter/features/auth/register_screen.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/auth/widgets/social_auth_section.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';
import 'package:loyallig_flutter/features/profile/pin_code_settings_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _googleLoading = false;
  String? _errorMessage;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null || _emailError != null || _passwordError != null) {
      setState(() {
        _errorMessage = null;
        _emailError = null;
        _passwordError = null;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loading || _googleLoading) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    String? emailErr;
    String? passErr;

    // E-poçt formatının yoxlanılması
    if (email.isEmpty) {
      emailErr = tr('auth_email_empty');
    } else if (!_isValidEmail(email)) {
      emailErr = tr('auth_email_invalid');
    }

    if (password.isEmpty) {
      passErr = tr('auth_password_empty');
    } else if (password.length < 6) {
      passErr = tr('auth_password_min');
    }

    // Əgər format xətası varsa, REQUEST GETMİR və border qırmızı olur!
    if (emailErr != null || passErr != null) {
      setState(() {
        _emailError = emailErr;
        _passwordError = passErr;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailError = null;
      _passwordError = null;
    });

    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final deviceName = await DeviceHelper.getDeviceName();

      debugPrint('==============================================');
      debugPrint('🔑 [LOGIN REQUEST GÖNDƏRİLİR]');
      debugPrint('📧 Email       : $email');
      debugPrint('🆔 Device ID   : $deviceId');
      debugPrint('📛 Device Name : $deviceName');
      debugPrint('==============================================');

      await _authService.loginWithFields(
        email: email,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
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

      String errorMsg = tr('auth_login_failed');
      if (e is DioException) {
        if (e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = data['errorMessage']?.toString() ??
                data['message']?.toString() ??
                data['title']?.toString() ??
                tr('auth_login_invalid_creds');
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
        // İstifadəçi hesabı seçmədən pəncərəni bağladı
        if (mounted) setState(() => _googleLoading = false);
        return;
      }

      if (!mounted) return;
      setState(() => _googleLoading = false);

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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  tr('auth_login_title'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // E-poçt
              CustomInput(
                label: tr('auth_email_label'),
                hint: tr('auth_email_hint'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                rightIcon: _emailError == null ? Icons.check_circle : null,
                error: _emailError,
                marginBottom: 16,
              ),

              // Şifrə
              CustomInput(
                label: tr('auth_password_label'),
                hint: tr('auth_password_hint'),
                controller: _passwordController,
                isPassword: true,
                error: _passwordError,
                marginBottom: 0,
              ),

              // forgotPassword: alignItems: 'flex-end', marginBottom: 20
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 18),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      tr('auth_forgot_password_link'),
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // Xəta Mesajı (Backend-dən gələn errorMessage)
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

              // loginButton
              PrimaryButton(
                label: _loading ? tr('common_loading') : tr('auth_login_button'),
                onPressed: (_loading || _googleLoading) ? () {} : _handleLogin,
                height: 52,
                borderRadius: 12,
              ),
              const SizedBox(height: 20),

              // divider & social buttons
              SocialAuthSection(
                onGoogleTap: (_loading || _googleLoading) ? null : _handleGoogleSignIn,
                isGoogleLoading: _googleLoading,
              ),
              const SizedBox(height: 24),

              // footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('auth_no_account_text'),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    child: Text(
                      tr('auth_register_link'),
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
