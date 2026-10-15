import 'package:flutter/material.dart';

class AuthPageScaffold extends StatelessWidget {
  const AuthPageScaffold({
    required this.child,
    this.horizontalPadding = 32,
    this.topPadding = 24,
    this.bottomPadding = 30,
    super.key,
  });

  final Widget child;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - (topPadding + bottomPadding),
                      ),
                      child: IntrinsicHeight(child: child),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
