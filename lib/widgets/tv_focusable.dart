import 'package:flutter/material.dart';

import '../utils/tv_key_helper.dart';

/// Focusable region that activates on D-Pad select/enter or on tap.
///
/// [builder] receives the current focus state so callers only describe how the
/// focused look differs from the resting one.
class TvFocusable extends StatelessWidget {
  final Widget Function(BuildContext context, bool focused) builder;
  final VoidCallback? onActivate;
  final bool autofocus;

  const TvFocusable({
    super.key,
    required this.builder,
    this.onActivate,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (onActivate != null && isTvActivateEvent(event)) {
          onActivate!();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) => GestureDetector(
          onTap: onActivate,
          child: builder(ctx, Focus.of(ctx).hasFocus),
        ),
      ),
    );
  }
}
