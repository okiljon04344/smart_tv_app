import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/tv_key_helper.dart';

/// Wraps a regular Material button so the TV remote can focus and activate it.
///
/// The wrapper owns the focus node; the inner button is excluded from focus
/// traversal so each action is a single D-Pad stop.
class TvAction extends StatelessWidget {
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onActivate;
  final Widget child;

  const TvAction({
    super.key,
    required this.focusNode,
    required this.enabled,
    required this.onActivate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (enabled && isTvActivateEvent(event)) {
          onActivate();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          foregroundDecoration: focusRing(
            context.colors,
            Focus.of(ctx).hasFocus,
          ),
          child: ExcludeFocus(child: child),
        ),
      ),
    );
  }
}
