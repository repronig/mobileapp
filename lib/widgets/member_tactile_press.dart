import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Subtle press feedback wrapper for buttons and compact tap targets.
class MemberTactilePress extends StatefulWidget {
  const MemberTactilePress({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<MemberTactilePress> createState() => _MemberTactilePressState();
}

class _MemberTactilePressState extends State<MemberTactilePress> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: widget.enabled && _pressed ? widget.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.emphasized,
        child: widget.child,
      ),
    );
  }
}
