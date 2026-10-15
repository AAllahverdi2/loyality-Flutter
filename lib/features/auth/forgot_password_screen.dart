import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/auth/models/forgot_password_request.dart';
import 'package:loyallig_flutter/features/auth/reset_password_screen.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _emailError;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
  }

  void _clearError() {
    if (_emailError != null || _errorMessage != null) {
      setState(() {
        _emailError = null;
        _errorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _handleSendCode() async {
    if (_loading) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = tr('auth_email_empty'));
      return;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = tr('auth_email_invalid'));
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _emailError = null;
    });

    try {
      final response = await _authService.forgotPassword(
        ForgotPasswordRequest(email: email),
      );

      final data = response.data;
      final isSuccess = data is Map ? (data['isSuccess'] == true) : true;

      if (!mounted) return;
      setState(() => _loading = false);

      if (isSuccess) {
        // Step 2: ResetPasswordScreen-ə yönləndiririk
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(email: email),
          ),
        );
      } else {
        setState(() {
          _errorMessage = data['errorMessage']?.toString() ?? tr('common_error');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = tr('auth_network_error');
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
                    color: isDark ? Colors.white : Colors.black,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Başlıq
              Text(
                tr('auth_forgot_title'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),

              // Açıqlama
              Text(
                tr('auth_forgot_desc'),
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // E-poçt daxil etmə xanası
              CustomInput(
                label: tr('auth_email_label'),
                hint: tr('email_hint'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                error: _emailError,
                marginBottom: 16,
              ),

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

              // Kodu göndər düyməsi
              PrimaryButton(
                label: _loading ? tr('auth_sending_code') : tr('auth_send_code_button'),
                onPressed: _loading ? () {} : _handleSendCode,
                height: 52,
                borderRadius: 12,
              ),
              const SizedBox(height: 32),

              // Footer: Şifrəni xatırladın? Daxil ol
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    tr('auth_remember_password_text'),
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
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
