import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../services/favorites_provider.dart';
import '../services/locale_provider.dart';
import '../theme/app_theme.dart';
import '../utils/tv_key_helper.dart';
import '../widgets/tv_button.dart';
import '../widgets/tv_focusable.dart';
import 'player_screen.dart';

const _cast = ['Amir K', 'Dilnoza M', 'Sardor T', 'Malika N'];

class DetailScreen extends StatefulWidget {
  final Content content;

  const DetailScreen({super.key, required this.content});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  int _lastBackPopMs = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.content;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (isTvBackEvent(event)) {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - _lastBackPopMs < 250) {
            return KeyEventResult.handled;
          }
          _lastBackPopMs = now;
          Navigator.maybePop(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Row(
              children: [
                _buildPoster(context, c),
                Expanded(child: _buildInfo(context, c)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(BuildContext context, Content c) {
    final colors = context.colors;
    final width = (MediaQuery.sizeOf(context).width * 0.3)
        .clamp(300.0, 420.0)
        .toDouble();
    return Container(
      width: width,
      height: double.infinity,
      color: posterTint(colors, c.colorCode),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _genreIcon(c.genre),
                  color: colors.onSurface.withValues(alpha: 0.6),
                  size: 72,
                ),
                const SizedBox(height: 16),
                Text(
                  c.genre.toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.75),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 32,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: colors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(c.rating, style: context.text.labelLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context, Content c) {
    final l = Provider.of<LocaleProvider>(context);
    final favorites = context.watch<FavoritesProvider>();
    final colors = context.colors;
    final isFav = favorites.isFavorite(c.id);
    final progress = favorites.getProgress(c.id);
    final muted = context.text.bodyLarge?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvFocusable(
            onActivate: () => Navigator.pop(context),
            builder: (context, focused) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              foregroundDecoration: focusRing(colors, focused),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(color: colors.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, color: colors.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Text(l.t('btn_back'), style: context.text.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            c.title,
            style: context.text.headlineMedium?.copyWith(
              fontSize: 40,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${c.year}  \u00b7  ${c.duration}  \u00b7  ${c.genre}',
            style: muted,
          ),
          const SizedBox(height: 16),
          if (progress > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: context.text.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(c.subtitle, style: context.text.titleMedium),
          const SizedBox(height: 8),
          Text(
            _description(c, l),
            style: muted?.copyWith(height: 1.6),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TvButton(
                icon: Icons.play_arrow_rounded,
                label: l.t('btn_watch'),
                tone: TvButtonTone.primary,
                autofocus: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerScreen(content: c)),
                  );
                },
              ),
              const SizedBox(width: 12),
              TvButton(
                icon: isFav ? Icons.favorite : Icons.add,
                label: isFav ? l.t('my_favorites') : l.t('btn_add_list'),
                onTap: () {
                  favorites.toggleFavorite(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? "'${c.title}' olib tashlandi"
                            : "'${c.title}' ${l.t('added_to_list')}",
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              TvButton(
                icon: Icons.share_outlined,
                label: l.t('btn_share'),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildCastRow(context, l),
        ],
      ),
    );
  }

  Widget _buildCastRow(BuildContext context, LocaleProvider l) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('cast_label'),
          style: context.text.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final name in _cast)
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colors.surfaceContainerHigh,
                      child: Text(name[0], style: context.text.titleMedium),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.split(' ')[0],
                      style: context.text.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  IconData _genreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'sci-fi':
        return Icons.rocket_launch;
      case 'drama':
        return Icons.theater_comedy;
      case 'horror':
        return Icons.nights_stay;
      case 'animation':
        return Icons.animation;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'adventure':
        return Icons.explore;
      case 'sport':
        return Icons.sports_soccer;
      case 'historical':
        return Icons.history_edu;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.movie;
    }
  }

  String _description(Content c, LocaleProvider l) {
    const keyByGenre = {
      'Sci-Fi': 'desc_scifi',
      'Drama': 'desc_drama',
      'Horror': 'desc_horror',
      'Animation': 'desc_animation',
      'Comedy': 'desc_comedy',
      'Adventure': 'desc_adventure',
      'Sport': 'desc_sport',
      'Romance': 'desc_romance',
    };
    return l.t(keyByGenre[c.genre] ?? 'desc_default');
  }
}
