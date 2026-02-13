import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final double height;
  final Widget? child;
  final AlignmentGeometry alignment;

  const GradientBackground({
    super.key,
    this.height = 220,
    this.child,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF9C27F0), Color(0xFFE91E63)],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
      ),
      child: child,
    );
  }
}
