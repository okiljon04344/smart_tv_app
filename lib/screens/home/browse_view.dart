import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/sample_data.dart';
import '../../models/content.dart';
import '../detail_screen.dart';
import '../player_screen.dart';
import '../../services/catalog_provider.dart';
import '../../services/locale_provider.dart';
import '../../services/favorites_provider.dart';
import '../../utils/tv_key_helper.dart';
import '../../widgets/content_card.dart';

// ─── Main Content ─────────────────────────────────────────────────────────────

class MainContent extends StatefulWidget {
  final int navIndex;
  final List<Category> categories;
  final VoidCallback onOpenSearch;

  const MainContent({
    super.key,
    required this.navIndex,
    required this.categories,
    required this.onOpenSearch,
  });

  @override
  State<MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<MainContent> {
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  static const _banners = [
    _BannerData(
      title: 'Galaktika Sargardoni',
      subtitle: 'Sci-Fi  •  2024  •  2s 18d  •  ★ 8.9',
      badgeKey: 'badge_recommended',
      colors: [Color(0xFF2E1A4E), Color(0xFF0D47A1)],
      icon: Icons.rocket_launch,
    ),
    _BannerData(
      title: 'Poytaxt Siri',
      subtitle: 'Drama  •  2024  •  Mavsum 3  •  ★ 9.3',
      badgeKey: 'badge_new_season',
      colors: [Color(0xFF3E2723), Color(0xFF4A1942)],
      icon: Icons.theater_comedy,
    ),
    _BannerData(
      title: "Yulduz Yo'li",
      subtitle: 'Animatsiya  •  2025  •  1s 35d  •  ★ 9.1',
      badgeKey: 'badge_top_rating',
      colors: [Color(0xFF1B5E20), Color(0xFF004D40)],
      icon: Icons.animation,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        setState(() => _bannerIndex = (_bannerIndex + 1) % _banners.length);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context, listen: false);
    final catalog = context.watch<CatalogProvider>();
    final favorites = context.watch<FavoritesProvider>();
    final continueList = favorites.getContinueWatching(allContent);
    final navTitles = [
      l.t('nav_home'),
      l.t('nav_movies'),
      l.t('nav_series'),
      l.t('nav_live'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (catalog.isOffline)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2B00),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFC107)),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Color(0xFFFFC107), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Offline mode: local catalog is shown',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _TopBar(
          title: navTitles[widget.navIndex],
          onSearchTap: widget.onOpenSearch,
        ),
        _FeaturedBanner(
          banners: _banners,
          currentIndex: _bannerIndex,
          onChanged: (i) => setState(() => _bannerIndex = i),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 30),
            itemCount:
                widget.categories.length +
                (continueList.isNotEmpty && widget.navIndex == 0 ? 1 : 0),
            itemBuilder: (ctx, i) {
              // Home ekranida birinchi bo'lib "Continue Watching" ko'rsatamiz
              if (widget.navIndex == 0 && continueList.isNotEmpty) {
                if (i == 0) {
                  return _ContinueWatchingRow(items: continueList);
                }
                return _CategoryRow(
                  titleKey: widget.categories[i - 1].name,
                  items: widget.categories[i - 1].items,
                  isFirst: false,
                );
              }
              return _CategoryRow(
                titleKey: widget.categories[i].name,
                items: widget.categories[i].items,
                isFirst: i == 0,
              );
            },
          ),
        ),
      ],
    );
  }
}

class CatalogLoadingView extends StatelessWidget {
  const CatalogLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF6C63FF)),
          SizedBox(height: 12),
          Text(
            'Loading catalog...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class CatalogErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const CatalogErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 34),
          const SizedBox(height: 8),
          const Text(
            'Catalog load failed',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─── Banner Data ──────────────────────────────────────────────────────────────

class _BannerData {
  final String title;
  final String subtitle;
  final String badgeKey;
  final List<Color> colors;
  final IconData icon;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.badgeKey,
    required this.colors,
    required this.icon,
  });
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchTap;
  const _TopBar({required this.title, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          _ClockWidget(),
          const SizedBox(width: 16),
          _IconBtn(Icons.search, onTap: onSearchTap),
          const SizedBox(width: 10),
          _IconBtn(
            Icons.notifications_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  backgroundColor: Color(0xFF6C63FF),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ClockWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final t =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return Text(
          t,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 17,
            fontWeight: FontWeight.w300,
            letterSpacing: 2,
          ),
        );
      },
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _IconBtn(this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (onTap != null && isTvActivateEvent(event)) {
          onTap!();
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
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: focused ? Colors.black : Colors.white,
                size: 20,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Featured Banner ──────────────────────────────────────────────────────────

class _FeaturedBanner extends StatelessWidget {
  final List<_BannerData> banners;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _FeaturedBanner({
    required this.banners,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final b = banners[currentIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(currentIndex),
        height: 210,
        margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: b.colors,
          ),
          boxShadow: [
            BoxShadow(
              color: b.colors[0].withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: 36,
              top: 0,
              bottom: 0,
              child: Icon(
                b.icon,
                size: 150,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      l.t(b.badgeKey),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    b.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _BannerBtn(
                        icon: Icons.play_arrow,
                        label: l.t('btn_watch'),
                        isPrimary: true,
                        onTap: () {
                          final items = allContent;
                          if (items.isEmpty) return;
                          final item = items[currentIndex % items.length];
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(content: item),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _BannerBtn(
                        icon: Icons.add,
                        label: l.t('btn_save'),
                        isPrimary: false,
                        onTap: () {
                          final items = allContent;
                          if (items.isEmpty) return;
                          final item = items[currentIndex % items.length];
                          context.read<FavoritesProvider>().toggleFavorite(
                            item,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "'${item.title}' ${l.t('added_to_list')}",
                              ),
                              backgroundColor: const Color(0xFF6C63FF),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 28,
              bottom: 18,
              child: Row(
                children: List.generate(
                  banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 6),
                    width: i == currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _BannerBtn({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (onTap != null && isTvActivateEvent(event)) {
          onTap!();
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
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white
                    : isPrimary
                    ? const Color(0xFF6C63FF)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          blurRadius: 14,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: focused ? Colors.black : Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: focused ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

// ─── Continue Watching Row ────────────────────────────────────────────────────

class _ContinueWatchingRow extends StatelessWidget {
  final List<Content> items;
  const _ContinueWatchingRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_outline,
                color: Color(0xFF6C63FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l.t('continue_watching'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: items.length,
            itemBuilder: (ctx, i) =>
                ContentCard(content: items[i], autofocus: i == 0),
          ),
        ),
      ],
    );
  }
}

// ─── Category Row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String titleKey;
  final List<Content> items;
  final bool isFirst;

  const _CategoryRow({
    required this.titleKey,
    required this.items,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
          child: Row(
            children: [
              Text(
                l.t(titleKey),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${items.length}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Focus(
                onKeyEvent: (node, event) {
                  if (items.isNotEmpty && isTvActivateEvent(event)) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(content: items.first),
                      ),
                    );
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (ctx) {
                    final focused = Focus.of(ctx).hasFocus;
                    return GestureDetector(
                      onTap: items.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(content: items.first),
                              ),
                            ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          color: focused
                              ? Colors.white
                              : const Color(0xFF6C63FF).withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        child: Text(l.t('see_all')),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            itemCount: items.length,
            itemBuilder: (ctx, i) =>
                ContentCard(content: items[i], autofocus: isFirst && i == 0),
          ),
        ),
      ],
    );
  }
}
