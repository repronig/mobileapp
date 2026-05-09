import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Soft elevated surface (inspiration-style cards): large radius, gentle shadow.
class MemberSurfaceCard extends StatefulWidget {
  const MemberSurfaceCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  State<MemberSurfaceCard> createState() => _MemberSurfaceCardState();
}

class _MemberSurfaceCardState extends State<MemberSurfaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadii.xl);

    Widget inner = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );
    if (widget.onTap != null) {
      inner = InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (value) => setState(() => _pressed = value),
        borderRadius: radius,
        child: inner,
      );
    }

    return AnimatedScale(
      scale: widget.onTap != null && _pressed ? 0.986 : 1,
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      child: Padding(
        padding: widget.margin ?? EdgeInsets.zero,
        child: Material(
          color: theme.colorScheme.surface,
          elevation: isDark ? 1.5 : 3,
          shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: widget.borderColor ??
                  theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.06),
            ),
          ),
          child: inner,
        ),
      ),
    );
  }
}
