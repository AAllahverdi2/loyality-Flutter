import 'package:flutter/material.dart';

/// Ekranın istənilən yerindən (o cümlədən ortasından) sağa çəkdikdə (swipe right)
/// əvvəlki səhifəyə və ya əsas səhifəyə (Home) qayıtmağı təmin edən qoruyucu və vizual vidjet.
class SwipeBackWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeBack;
  final bool enabled;

  const SwipeBackWrapper({
    required this.child,
    this.onSwipeBack,
    this.enabled = true,
    super.key,
  });

  @override
  State<SwipeBackWrapper> createState() => _SwipeBackWrapperState();
}

class _SwipeBackWrapperState extends State<SwipeBackWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isAnimating = false;
  double _screenWidth = 375.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragOffset = _slideAnimation.value;
          });
        }
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted && _isAnimating) {
            _isAnimating = false;
            if (widget.onSwipeBack != null) {
              widget.onSwipeBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        }
      });

    _slideAnimation = const AlwaysStoppedAnimation<double>(0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled || _isAnimating) return;
    _animController.stop();
    _isDragging = true;
    _dragOffset = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || !_isDragging || _isAnimating) return;
    if (details.delta.dx > 0 || _dragOffset > 0) {
      setState(() {
        _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, _screenWidth);
      });
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enabled || !_isDragging || _isAnimating) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    final shouldPop = velocity > 250 || _dragOffset > (_screenWidth * 0.20);

    if (shouldPop) {
      _animateExit();
    } else {
      _animateCancel();
    }
  }

  void _onHorizontalDragCancel() {
    if (!widget.enabled || !_isDragging || _isAnimating) return;
    _isDragging = false;
    _animateCancel();
  }

  void _animateExit() {
    _isAnimating = true;
    final remainingDistance = (_screenWidth - _dragOffset).clamp(0.0, _screenWidth);
    final remainingRatio = (remainingDistance / _screenWidth).clamp(0.25, 1.0);
    final durationMs = (240 * remainingRatio).toInt();

    _animController.duration = Duration(milliseconds: durationMs);
    _slideAnimation = Tween<double>(begin: _dragOffset, end: _screenWidth).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  void _animateCancel() {
    final cancelRatio = (_dragOffset / _screenWidth).clamp(0.2, 1.0);
    final durationMs = (180 * cancelRatio).toInt();

    _animController.duration = Duration(milliseconds: durationMs);
    _slideAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        _screenWidth = constraints.maxWidth > 0 ? constraints.maxWidth : 375.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Arxa fon üzərində tündləşdirmə
            if (_dragOffset > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.12 * (1.0 - (_dragOffset / _screenWidth).clamp(0.0, 1.0)),
                    ),
                  ),
                ),
              ),

            // Sürüşən səhifə (sol kənarda kölgə ilə)
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: _dragOffset > 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(-4, 0),
                          ),
                        ]
                      : null,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: _onHorizontalDragStart,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onHorizontalDragCancel: _onHorizontalDragCancel,
                  child: widget.child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

