import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';

export 'package:loyallig_flutter/core/widgets/custom_input.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.hint,
    this.controller,
    this.isPassword = false,
    this.showSuccessIcon = false,
    this.error,
    this.rightIcon,
    this.onRightIconPress,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final bool isPassword;
  final bool showSuccessIcon;
  final String? error;
  final IconData? rightIcon;
  final VoidCallback? onRightIconPress;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return CustomInput(
      label: label,
      hint: hint,
      controller: controller,
      isPassword: isPassword,
      error: error,
      rightIcon: rightIcon ?? (showSuccessIcon ? Icons.check_circle : null),
      onRightIconPress: onRightIconPress,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

