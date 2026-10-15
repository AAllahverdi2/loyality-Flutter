import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class CustomInput extends StatefulWidget {
  const CustomInput({
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.error,
    this.rightIcon,
    this.onRightIconPress,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.focusNode,
    this.marginBottom = 20,
    super.key,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final String? error;
  final IconData? rightIcon;
  final VoidCallback? onRightIconPress;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;
  final double marginBottom;

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isSecure = true;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _isSecure = widget.isPassword;
  }

  @override
  void didUpdateWidget(covariant CustomInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPassword != widget.isPassword) {
      _isSecure = widget.isPassword;
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _toggleSecure() {
    setState(() => _isSecure = !_isSecure);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final inputBg =
        isDark ? AppColors.darkInputBackground : AppColors.inputBackground;
    final borderColor = widget.error != null && widget.error!.isNotEmpty
        ? AppColors.error
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return Container(
      margin: EdgeInsets.only(bottom: widget.marginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // label
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // inputContainer
          GestureDetector(
            onTap: widget.enabled && !widget.readOnly
                ? () => _effectiveFocusNode.requestFocus()
                : null,
            behavior: HitTestBehavior.translucent,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.enabled
                    ? inputBg
                    : (isDark
                        ? const Color(0xFF18181B)
                        : const Color(0xFFF3F4F6)),
                border: Border.all(
                  color: widget.enabled
                      ? borderColor
                      : (isDark
                          ? const Color(0xFF27272A)
                          : const Color(0xFFE5E7EB)),
                  width:
                      widget.error != null && widget.error!.isNotEmpty ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _effectiveFocusNode,
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      autofocus: widget.autofocus,
                      obscureText: widget.isPassword && _isSecure,
                      enableSuggestions: !widget.isPassword,
                      autocorrect: !widget.isPassword,
                      keyboardType: widget.keyboardType ?? TextInputType.text,
                      inputFormatters: widget.inputFormatters,
                      textInputAction: widget.textInputAction ??
                          (widget.isPassword
                              ? TextInputAction.done
                              : TextInputAction.next),
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      textAlignVertical: TextAlignVertical.center,
                      cursorColor: AppColors.base,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.enabled
                            ? textColor
                            : (isDark
                                ? const Color(0xFF71717A)
                                : const Color(0xFF9CA3AF)),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.normal,
                        ),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (widget.isPassword) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _toggleSecure,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        _isSecure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ] else if (widget.rightIcon != null) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onRightIconPress,
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        widget.rightIcon,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // errorText
          if (widget.error != null && widget.error!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
