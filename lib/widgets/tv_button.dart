import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tv_focusable.dart';

enum TvButtonTone { primary, secondary, danger }

/// Flat button for D-Pad navigation. The focused state is an off-white ring.
class TvButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TvButtonTone tone;
  final bool autofocus;
  final VoidCallback? onTap;

  const TvButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.tone = TvButtonTone.secondary,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, border) = switch (tone) {
      TvButtonTone.primary => (
        colors.primary,
        colors.onPrimary,
        colors.primary,
      ),
      TvButtonTone.secondary => (
        colors.surfaceContainerHigh,
        colors.onSurface,
        colors.outline,
      ),
      TvButtonTone.danger => (Colors.transparent, colors.error, colors.error),
    };

    return TvFocusable(
      autofocus: autofocus,
      onActivate: onTap,
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: border),
        ),
        foregroundDecoration: focusRing(colors, focused),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: context.text.labelLarge?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
