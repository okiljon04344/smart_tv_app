import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/content.dart';
import '../../services/catalog_provider.dart';
import '../../services/favorites_provider.dart';
import '../../services/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_card.dart';
import '../../widgets/tv_button.dart';
import '../../widgets/tv_focusable.dart';
import '../detail_screen.dart';
import '../player_screen.dart';

const double _hPadding = AppSpacing.screenPadding;

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
      subtitle: 'Sci-Fi  ·  2024  ·  2s 18d  ·  8.9',
      badgeKey: 'badge_recommended',
      colorCode: 0xFF1A237E,
    ),
    _BannerData(
      title: 'Poytaxt Siri',
      subtitle: 'Drama  ·  2024  ·  Mavsum 3  ·  9.3',
      badgeKey: 'badge_new_season',
      colorCode: 0xFF880E4F,
    ),
    _BannerData(
      title: "Yulduz Yo'li",
      subtitle: 'Animatsiya  ·  2025  ·  1s 35d  ·  9.1',
      badgeKey: 'badge_top_rating',
      colorCode: 0xFF1B5E20,
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
    final colors = context.colors;
    final continueList = favorites.getContinueWatching(allContent);
    final showContinue = continueList.isNotEmpty && widget.navIndex == 0;
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
            margin: const EdgeInsets.fromLTRB(_hPadding, 12, _hPadding, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: colors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Offline mode: local catalog is shown',
                    style: context.text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        _TopBar(
          title: navTitles[widget.navIndex],
          onSearchTap: widget.onOpenSearch,
        ),
        _FeaturedBanner(banners: _banners, currentIndex: _bannerIndex),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 32),
            itemCount: widget.categories.length + (showContinue ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (showContinue) {
                if (i == 0) {
                  return _ContinueWatchingRow(items: continueList);
                }
                return _CategoryRow(
                  titleKey: widget.categories[i - 1].name,
                  items: widget.categories[i - 1].items,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading catalog...',
            style: context.text.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
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
          Icon(Icons.error_outline, color: context.colors.error, size: 40),
          const SizedBox(height: 12),
          Text('Catalog load failed', style: context.text.bodyLarge),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final String badgeKey;
  final int colorCode;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.badgeKey,
    required this.colorCode,
  });
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onSearchTap;
  const _TopBar({required this.title, required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPadding, vertical: 16),
      child: Row(
        children: [
          Text(title, style: context.text.headlineMedium),
          const Spacer(),
          const _Clock(),
          const SizedBox(width: 20),
          _IconBtn(Icons.search, onTap: onSearchTap),
          const SizedBox(width: 12),
          _IconBtn(
            Icons.notifications_outlined,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
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

class _Clock extends StatelessWidget {
  const _Clock();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, _) {
        final now = DateTime.now();
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        return Text(
          '$hh:$mm',
          style: context.text.titleLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
            fontWeight: FontWeight.w400,
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
    final colors = context.colors;
    return TvFocusable(
      onActivate: onTap,
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(10),
        foregroundDecoration: focusRing(colors, focused),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        child: Icon(icon, color: colors.onSurface, size: 24),
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  final List<_BannerData> banners;
  final int currentIndex;

  const _FeaturedBanner({required this.banners, required this.currentIndex});

  void _watch(BuildContext context) {
    final items = allContent;
    if (items.isEmpty) return;
    final item = items[currentIndex % items.length];
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(content: item)),
    );
  }

  void _save(BuildContext context, LocaleProvider l) {
    final items = allContent;
    if (items.isEmpty) return;
    final item = items[currentIndex % items.length];
    context.read<FavoritesProvider>().toggleFavorite(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'${item.title}' ${l.t('added_to_list')}"),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final colors = context.colors;
    final b = banners[currentIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: Container(
        key: ValueKey(currentIndex),
        height: 224,
        margin: const EdgeInsets.symmetric(horizontal: _hPadding, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: posterTint(colors, b.colorCode),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.t(b.badgeKey).toUpperCase(),
                  style: context.text.labelMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(b.title, style: context.text.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  b.subtitle,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TvButton(
                      icon: Icons.play_arrow_rounded,
                      label: l.t('btn_watch'),
                      tone: TvButtonTone.primary,
                      onTap: () => _watch(context),
                    ),
                    const SizedBox(width: 12),
                    TvButton(
                      icon: Icons.add,
                      label: l.t('btn_save'),
                      onTap: () => _save(context, l),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Row(
                children: List.generate(
                  banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(left: 6),
                    width: i == currentIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == currentIndex
                          ? colors.onSurface
                          : colors.onSurface.withValues(alpha: 0.3),
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

class _RowHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final String? count;

  const _RowHeader({required this.title, this.count, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPadding, 16, _hPadding, 4),
      child: Row(
        children: [
          Text(title, style: context.text.titleLarge),
          if (count != null) ...[
            const SizedBox(width: 10),
            Text(
              count!,
              style: context.text.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  final List<Content> items;
  final bool autofocusFirst;

  const _CardList({required this.items, this.autofocusFirst = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ContentCard.rowHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _hPadding - 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) =>
            ContentCard(content: items[i], autofocus: autofocusFirst && i == 0),
      ),
    );
  }
}

class _ContinueWatchingRow extends StatelessWidget {
  final List<Content> items;
  const _ContinueWatchingRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowHeader(title: l.t('continue_watching')),
        _CardList(items: items, autofocusFirst: true),
      ],
    );
  }
}

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
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RowHeader(
          title: l.t(titleKey),
          count: '${items.length}',
          trailing: TvFocusable(
            onActivate: items.isEmpty
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailScreen(content: items.first),
                    ),
                  ),
            builder: (context, focused) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              foregroundDecoration: focusRing(colors, focused),
              child: Text(
                l.t('see_all'),
                style: context.text.labelLarge?.copyWith(
                  color: focused ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        _CardList(items: items, autofocusFirst: isFirst),
      ],
    );
  }
}
