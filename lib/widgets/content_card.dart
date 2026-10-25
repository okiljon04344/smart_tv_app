import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../screens/detail_screen.dart';
import '../services/favorites_provider.dart';
import '../theme/app_theme.dart';
import '../utils/tv_key_helper.dart';

class ContentCard extends StatefulWidget {
  final Content content;
  final bool autofocus;

  const ContentCard({super.key, required this.content, this.autofocus = false});

  /// Height a horizontal row must reserve for one card.
  static const double rowHeight = 208;

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> {
  bool _focused = false;

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(content: widget.content)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();
    final colors = context.colors;
    final content = widget.content;
    final isFav = favorites.isFavorite(content.id);
    final progress = favorites.getProgress(content.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        onKeyEvent: (node, event) {
          if (isTvActivateEvent(event)) {
            _openDetail(context);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: () => _openDetail(context),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _focused ? 1.05 : 1,
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      foregroundDecoration: focusRing(colors, _focused),
                      decoration: BoxDecoration(
                        color: posterTint(colors, content.colorCode),
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: colors.onSurface.withValues(alpha: 0.35),
                              size: 44,
                            ),
                          ),
                          if (progress > 0)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: colors.surface.withValues(
                                  alpha: 0.6,
                                ),
                                minHeight: 4,
                              ),
                            ),
                          if (content.isNew)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _Badge(
                                text: 'NEW',
                                background: colors.primary,
                                foreground: colors.onPrimary,
                              ),
                            ),
                          if (content.isHD && !content.isNew)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _Badge(
                                text: 'HD',
                                background: colors.surface.withValues(
                                  alpha: 0.8,
                                ),
                                foreground: colors.onSurface,
                              ),
                            ),
                          if (_focused)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => context
                                    .read<FavoritesProvider>()
                                    .toggleFavorite(content),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colors.surface.withValues(
                                      alpha: 0.8,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav
                                        ? colors.primary
                                        : colors.onSurface,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content.title,
                    style: context.text.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${content.year}  ·  ${content.rating}',
                    style: context.text.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
