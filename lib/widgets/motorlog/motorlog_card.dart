import 'package:flutter/material.dart';

class MotorLogCard extends StatelessWidget {
  const MotorLogCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
