import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({
    this.width,
    this.height,
    this.borderRadius,
    this.isCircle = false,
    this.margin,
    super.key,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final EdgeInsetsGeometry? margin;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFF3F4F6);

    return Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle
                  ? null
                  : (widget.borderRadius ?? BorderRadius.circular(8)),
              gradient: LinearGradient(
                begin: const Alignment(-1.0, 0),
                end: const Alignment(1.0, 0),
                stops: const [0.0, 0.5, 1.0],
                colors: [baseColor, highlightColor, baseColor],
                transform: _SlidingGradientTransform(slidePercent: progress * 2.5 - 1.0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
