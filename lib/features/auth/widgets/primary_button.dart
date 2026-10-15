import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.height = 50,
    this.borderRadius = 12,
    this.fontSize = 16,
    this.paddingHorizontal,
    this.paddingTop,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final double height;
  final double borderRadius;
  final double fontSize;
  final double? paddingHorizontal;
  final double? paddingTop;

  @override
  Widget build(BuildContext context) {
    Widget button = SizedBox(
      width: double.infinity,
      height: height,
      child: outlined
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: AppColors.base,
                  width: 1.0,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: onPressed,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: AppColors.base,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(borderRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: onPressed,
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );

    if (paddingHorizontal != null || paddingTop != null) {
      button = Padding(
        padding: EdgeInsets.only(
          left: paddingHorizontal ?? 0,
          right: paddingHorizontal ?? 0,
          top: paddingTop ?? 0,
        ),
        child: button,
      );
    }

    return button;
  }
}
