import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/auth/models/change_password_request.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool showHeader;

  const ChangePasswordScreen({
    super.key,
    this.showHeader = true,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_clearErrors);
    _newPasswordController.addListener(_clearErrors);
    _confirmPasswordController.addListener(_clearErrors);
  }

  void _clearErrors() {
    if (_currentPasswordError != null ||
        _newPasswordError != null ||
        _confirmPasswordError != null) {
      setState(() {
        _currentPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_clearErrors);
    _newPasswordController.removeListener(_clearErrors);
    _confirmPasswordController.removeListener(_clearErrors);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_loading) return;

    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    String? currentErr;
    String? newErr;
    String? confirmErr;

    if (current.isEmpty) {
      currentErr = tr('security_current_empty');
    }

    if (newPass.isEmpty) {
      newErr = tr('security_new_empty');
    } else if (newPass.length < 6) {
      newErr = tr('security_min_chars');
    } else if (!RegExp(r'[A-Z]').hasMatch(newPass)) {
      newErr = tr('security_require_uppercase');
    } else if (!RegExp(r'[0-9]').hasMatch(newPass)) {
      newErr = tr('security_require_number');
    } else if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(newPass)) {
      newErr = tr('security_require_special');
    } else if (current == newPass) {
      newErr = tr('security_same_as_current');
    }

    if (confirm.isEmpty) {
      confirmErr = tr('security_confirm_empty');
    } else if (newPass != confirm) {
      confirmErr = tr('security_mismatch');
    }

    if (currentErr != null || newErr != null || confirmErr != null) {
      setState(() {
        _currentPasswordError = currentErr;
        _newPasswordError = newErr;
        _confirmPasswordError = confirmErr;
      });
      return;
    }

    setState(() {
      _loading = true;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    try {
      final response = await _authService.changePassword(
        ChangePasswordRequest(
          currentPassword: current,
          newPassword: newPass,
          confirmNewPassword: confirm,
        ),
      );

      final data = response.data;
      final isSuccess = data is Map
          ? (data['isSuccess'] == true)
          : (response.statusCode == 200 || response.statusCode == 204);

      if (!mounted) return;
      setState(() => _loading = false);

      if (isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('security_success')),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        if (widget.showHeader) {
          Navigator.of(context).pop();
        }
      } else {
        final msg = data is Map
            ? (data['errorMessage']?.toString() ??
                tr('security_failed'))
            : tr('security_failed');
        _showError(msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = tr('security_failed');
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
      _showError(errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final dividerColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);

    final Widget mainBody = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

                    // Icon and info
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFFC91C1C),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('security_change_title'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              tr('security_desc'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form
                    CustomInput(
                      label: tr('security_current_password'),
                      controller: _currentPasswordController,
                      hint: tr('security_current_password_hint'),
                      isPassword: true,
                      error: _currentPasswordError,
                      marginBottom: 16,
                    ),

                    Container(
                      height: 1,
                      color: dividerColor,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),

                    CustomInput(
                      label: tr('security_new_password'),
                      controller: _newPasswordController,
                      hint: tr('security_new_password_hint'),
                      isPassword: true,
                      error: _newPasswordError,
                      marginBottom: 16,
                    ),

                    CustomInput(
                      label: tr('security_confirm_new_password'),
                      controller: _confirmPasswordController,
                      hint: tr('security_confirm_new_password_hint'),
                      isPassword: true,
                      error: _confirmPasswordError,
                      marginBottom: 32,
                    ),

                    // Submit Button
                    PrimaryButton(
                      label: _loading
                          ? tr('security_updating')
                          : tr('security_change_button'),
                      onPressed: _loading ? () {} : _handleSave,
                      height: 52,
                      borderRadius: 14,
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
                          color: isDark ? Colors.white : Colors.black,
                          size: 26,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          tr('security_change_title'),
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
