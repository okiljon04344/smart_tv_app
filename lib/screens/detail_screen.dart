import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content.dart';
import '../services/locale_provider.dart';
import '../services/favorites_provider.dart';
import '../utils/tv_key_helper.dart';
import 'player_screen.dart';

bool _isTvActivateEvent(KeyEvent event) => isTvActivateEvent(event);
bool _isTvBackEvent(KeyEvent event) => isTvBackEvent(event);

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
        if (_isTvBackEvent(event)) {
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
        backgroundColor: const Color(0xFF0A0A0F),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Row(
              children: [
                // Left: Poster
                _buildPoster(c),
                // Right: Info
                Expanded(child: _buildInfo(context, c)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(Content c) {
    final width = (MediaQuery.sizeOf(context).width * 0.3)
        .clamp(300.0, 420.0)
        .toDouble();
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Color(c.colorCode),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(c.colorCode),
            Color(c.colorCode).withValues(alpha: 0.6),
            const Color(0xFF0A0A0F),
          ],
          stops: const [0, 0.6, 1],
        ),
      ),
      child: Stack(
        children: [
          // Dekorativ pattern
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Janr belgisi
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _genreIcon(c.genre),
                    color: Colors.white,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    c.genre.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rating badge (top right)
          Positioned(
            top: 30,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5C518),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.black, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    c.rating,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
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
    final isFav = favorites.isFavorite(c.id);
    final progress = favorites.getProgress(c.id);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Focus(
            autofocus: false,
            onKeyEvent: (node, event) {
              if (_isTvActivateEvent(event)) {
                Navigator.pop(context);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (ctx) {
                final focused = Focus.of(ctx).hasFocus;
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: focused
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: focused
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.t('btn_back'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            c.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Meta info
          Row(
            children: [
              _MetaBadge(label: c.year, color: const Color(0xFF6C63FF)),
              const SizedBox(width: 10),
              _MetaBadge(label: c.duration, color: Colors.white24),
              const SizedBox(width: 10),
              _MetaBadge(label: c.genre, color: Colors.white24),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar (shown if the title has been watched)
          if (progress > 0) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.red,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          // Subtitle
          Text(
            c.subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            _generateDescription(c, l),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 16,
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              _ActionButton(
                icon: Icons.play_arrow_rounded,
                label: l.t('btn_watch'),
                primary: true,
                autofocus: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerScreen(content: c)),
                  );
                },
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: isFav ? Icons.favorite : Icons.add,
                label: isFav ? l.t('my_favorites') : l.t('btn_add_list'),
                primary: isFav,
                onTap: () {
                  favorites.toggleFavorite(c);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? "'${c.title}' olib tashlandi"
                            : "'${c.title}' ${l.t('added_to_list')}",
                      ),
                      backgroundColor: const Color(0xFF6C63FF),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.share_outlined,
                label: l.t('btn_share'),
                primary: false,
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cast info
          _buildCastRow(c, l),
        ],
      ),
    );
  }

  Widget _buildCastRow(Content c, LocaleProvider l) {
    final cast = _generateCast(c.genre);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('cast_label'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: cast
              .map(
                (name) => Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(
                          0xFF6C63FF,
                        ).withValues(alpha: 0.3),
                        child: Text(
                          name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name.split(' ')[0],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
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

  String _generateDescription(Content c, LocaleProvider l) {
    final keyMap = {
      'Sci-Fi': 'desc_scifi',
      'Drama': 'desc_drama',
      'Horror': 'desc_horror',
      'Animation': 'desc_animation',
      'Comedy': 'desc_comedy',
      'Adventure': 'desc_adventure',
      'Sport': 'desc_sport',
      'Romance': 'desc_romance',
    };
    final key = keyMap[c.genre] ?? 'desc_default';
    return l.t(key);
  }

  List<String> _generateCast(String genre) {
    return ['Amir K', 'Dilnoza M', 'Sardor T', 'Malika N'];
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final bool autofocus;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white
                    : primary
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: focused
                      ? Colors.white
                      : primary
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : primary
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          blurRadius: 15,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: focused
                        ? Colors.black
                        : primary
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: focused
                          ? Colors.black
                          : primary
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
