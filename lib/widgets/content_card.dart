import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/content.dart';
import '../screens/home_screen.dart';
import '../screens/detail_screen.dart';
import '../services/favorites_provider.dart';
import 'package:provider/provider.dart';

bool _isTvActivateEvent(KeyEvent event) {
  final key = event.logicalKey;
  final isActivate =
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.gameButtonA;
  if (!isActivate) return false;
  if (key == LogicalKeyboardKey.select) {
    return event is KeyDownEvent || event is KeyUpEvent;
  }
  return event is KeyDownEvent;
}

class ContentCard extends StatefulWidget {
  final Content content;
  final bool autofocus;

  const ContentCard({super.key, required this.content, this.autofocus = false});

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
    final isFav = favorites.isFavorite(widget.content.id);
    final progress = favorites.getProgress(widget.content.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Actions(
        actions: <Type, Action<Intent>>{
          AppSelectIntent: CallbackAction<AppSelectIntent>(
            onInvoke: (_) {
              _openDetail(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: widget.autofocus,
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
          onKeyEvent: (node, event) {
            if (_isTvActivateEvent(event)) {
              _openDetail(context);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: GestureDetector(
            onTap: () => _openDetail(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 220,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _focused ? 1.04 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      // Background color
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Container(
                          color: Color(widget.content.colorCode),
                          child: Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Title and rating
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: progress > 0 ? 14 : 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.content.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  widget.content.rating,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Progress bar
                      if (progress > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                            minHeight: 3,
                          ),
                        ),
                      // NEW badge
                      if (widget.content.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _Badge(text: 'NEW', color: Colors.purple),
                        ),
                      // HD badge
                      if (widget.content.isHD && !widget.content.isNew)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: _Badge(text: 'HD', color: Colors.black54),
                        ),
                      // Favorite button (shown when focused)
                      if (_focused)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => context
                                .read<FavoritesProvider>()
                                .toggleFavorite(widget.content),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
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
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
