import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/sample_data.dart';
import '../models/content.dart';
import 'admin_screen.dart';
import 'detail_screen.dart';
import 'player_screen.dart';
import '../services/auth_provider.dart';
import '../services/catalog_provider.dart';
import '../services/locale_provider.dart';
import '../services/favorites_provider.dart';
import '../utils/tv_key_helper.dart';
import '../widgets/content_card.dart';

class AppSelectIntent extends Intent {
  const AppSelectIntent();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  final FocusScopeNode _sidebarScope = FocusScopeNode(debugLabel: 'sidebar');
  final FocusScopeNode _contentScope = FocusScopeNode(debugLabel: 'content');

  @override
  void dispose() {
    _sidebarScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  void _selectNav(int i) {
    setState(() => _selectedNavIndex = i);
    // After nav change, move focus into content area
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentScope.requestFocus();
    });
  }

  List<_NavItemData> _buildNavItems(LocaleProvider l) => [
    _NavItemData(Icons.home_rounded, l.t('nav_home')),
    _NavItemData(Icons.movie_outlined, l.t('nav_movies')),
    _NavItemData(Icons.live_tv_outlined, l.t('nav_series')),
    _NavItemData(Icons.stream, l.t('nav_live')),
    _NavItemData(Icons.favorite_border, l.t('nav_my_list')),
    _NavItemData(Icons.search, l.t('nav_search')),
    _NavItemData(Icons.settings_outlined, l.t('nav_settings')),
  ];

  List<Category> get _currentCategories {
    switch (_selectedNavIndex) {
      case 0:
        return categories;
      case 1:
        return categories.where((c) => c.name != 'cat_live').toList();
      case 2:
        return [categories[1]];
      case 3:
        return [categories[2]];
      default:
        return categories;
    }
  }

  Widget _buildContent() {
    final catalog = context.watch<CatalogProvider>();
    final showCatalogState = _selectedNavIndex <= 3;
    if (showCatalogState && catalog.isLoading && categories.isEmpty) {
      return const _CatalogLoadingView();
    }
    if (showCatalogState && catalog.error != null && categories.isEmpty) {
      return _CatalogErrorView(onRetry: catalog.refresh);
    }

    switch (_selectedNavIndex) {
      case 4:
        return const _MyListScreen();
      case 5:
        return const _SearchScreen();
      case 6:
        return _SettingsScreen(
          onExitToSidebar: () => _sidebarScope.requestFocus(),
        );
      default:
        return _MainContent(
          navIndex: _selectedNavIndex,
          categories: _currentCategories,
          onOpenSearch: () => _selectNav(5),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final navItems = _buildNavItems(l);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Row(
        children: [
          FocusScope(
            node: _sidebarScope,
            child: _Sidebar(
              navItems: navItems,
              selectedIndex: _selectedNavIndex,
              onItemSelected: _selectNav,
              onEnterContent: () => _contentScope.requestFocus(),
            ),
          ),
          Expanded(
            child: FocusScope(
              node: _contentScope,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  final movedLeft =
                      FocusManager.instance.primaryFocus?.focusInDirection(
                        TraversalDirection.left,
                      ) ??
                      false;
                  if (!movedLeft) {
                    _sidebarScope.requestFocus();
                  }
                  return KeyEventResult.handled;
                }
                // Back / Escape → return to sidebar
                if (isTvBackEvent(event)) {
                  _sidebarScope.requestFocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                // KeyedSubtree forces re-autofocus when switching sections
                child: KeyedSubtree(
                  key: ValueKey(_selectedNavIndex),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData(this.icon, this.label);
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItemData> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onEnterContent;

  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onEnterContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 102,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          _buildLogo(),
          const SizedBox(height: 24),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: navItems.length,
              itemBuilder: (context, i) => _SidebarItem(
                data: navItems[i],
                isSelected: selectedIndex == i,
                autofocus: i == selectedIndex,
                onTap: () => onItemSelected(i),
                onEnterContent: onEnterContent,
              ),
            ),
          ),
          _buildProfile(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return const Column(
      children: [
        Icon(Icons.tv, color: Color(0xFF6C63FF), size: 34),
        SizedBox(height: 4),
        Text(
          'SMART\nTV',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6C63FF),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          color: Colors.white.withValues(alpha: 0.06),
        ),
        const SizedBox(height: 16),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 22),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItemData data;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onTap;
  final VoidCallback onEnterContent;

  const _SidebarItem({
    required this.data,
    required this.isSelected,
    this.autofocus = false,
    required this.onTap,
    required this.onEnterContent,
  });

  void _select() {
    onTap();
    onEnterContent();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Focus(
        autofocus: autofocus,
        onKeyEvent: (node, event) {
          // ArrowRight → move into content
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _select();
            return KeyEventResult.handled;
          }
          if (isTvActivateEvent(event)) {
            _select();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (ctx) {
            final focused = Focus.of(ctx).hasFocus;
            return GestureDetector(
              onTap: _select,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: focused
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                      : isSelected
                      ? const Color(0xFF6C63FF).withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: focused
                        ? const Color(0xFF6C63FF)
                        : isSelected
                        ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      data.icon,
                      color: focused || isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white.withValues(alpha: 0.4),
                      size: 24,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: focused || isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 9.5,
                        fontWeight: focused || isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Main Content ─────────────────────────────────────────────────────────────

class _MainContent extends StatefulWidget {
  final int navIndex;
  final List<Category> categories;
  final VoidCallback onOpenSearch;

  const _MainContent({
    required this.navIndex,
    required this.categories,
    required this.onOpenSearch,
  });

  @override
  State<_MainContent> createState() => _MainContentState();
}

class _MainContentState extends State<_MainContent> {
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

class _CatalogLoadingView extends StatelessWidget {
  const _CatalogLoadingView();

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

class _CatalogErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _CatalogErrorView({required this.onRetry});

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
                          context.read<FavoritesProvider>().toggleFavorite(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("'${item.title}' ${l.t('added_to_list')}"),
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

// ─── My List Screen ───────────────────────────────────────────────────────────

class _MyListScreen extends StatelessWidget {
  const _MyListScreen();

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final favorites = context.watch<FavoritesProvider>();
    final all = allContent;
    final favList = favorites.getFavorites(all);
    final continueList = favorites.getContinueWatching(all);

    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('nav_my_list'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: favList.isEmpty && continueList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.white.withValues(alpha: 0.2),
                          size: 72,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.t('my_list_empty'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      if (continueList.isNotEmpty) ...[
                        Text(
                          l.t('continue_watching'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 175,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: continueList.length,
                            itemBuilder: (ctx, i) => ContentCard(
                              content: continueList[i],
                              autofocus: i == 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (favList.isNotEmpty) ...[
                        Text(
                          l.t('my_favorites'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 175,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: favList.length,
                            itemBuilder: (ctx, i) => ContentCard(
                              content: favList[i],
                              autofocus: continueList.isEmpty && i == 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Screen ────────────────────────────────────────────────────────────

class _SearchScreen extends StatefulWidget {
  const _SearchScreen();

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  String _query = '';
  final _controller = TextEditingController();

  List<Content> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return allContent
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.genre.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('search_title'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: l.t('search_hint'),
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          const SizedBox(height: 30),
          if (_query.isEmpty) ...[
            Text(
              l.t('search_popular_tags'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  ['Sci-Fi', 'Drama', 'Animation', 'Comedy', 'Horror', 'Sport']
                      .map(
                        (tag) => Focus(
                          onKeyEvent: (node, event) {
                            if (isTvActivateEvent(event)) {
                              _controller.text = tag;
                              setState(() => _query = tag);
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(
                            builder: (ctx) {
                              final focused = Focus.of(ctx).hasFocus;
                              return GestureDetector(
                                onTap: () {
                                  _controller.text = tag;
                                  setState(() => _query = tag);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: focused
                                        ? const Color(0xFF6C63FF)
                                        : Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: focused
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                      width: focused ? 2 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: focused
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                      .toList(),
            ),
          ] else ...[
            Text(
              l.t('search_results', n: '${_results.length}'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 175,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _results.length,
                itemBuilder: (ctx, i) =>
                    ContentCard(content: _results[i], autofocus: i == 0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Settings Screen ──────────────────────────────────────────────────────────

class _SettingsScreen extends StatefulWidget {
  final VoidCallback onExitToSidebar;
  const _SettingsScreen({required this.onExitToSidebar});

  @override
  State<_SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<_SettingsScreen> {
  static const _kBrightness = 'settings_brightness';
  static const _kContrast = 'settings_contrast';
  static const _kVolume = 'settings_volume';
  static const _kMuted = 'settings_muted';
  static const _kSoundEffects = 'settings_sound_effects';
  static const _kParentalControl = 'settings_parental_control';

  int _selectedIndex = 0;
  final FocusScopeNode _rightPanelScope = FocusScopeNode();
  late final List<FocusNode> _menuNodes;

  // Mutable state
  double _brightness = 0.7;
  double _contrast = 0.6;
  double _volume = 0.8;
  bool _muted = false;
  bool _soundEffects = true;
  bool _parentalControl = false;
  bool _historyCleared = false;

  @override
  void initState() {
    super.initState();
    _menuNodes = List.generate(
      7,
      (i) => FocusNode(debugLabel: 'settings_menu_$i'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusSelectedMenuItem();
    });
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _brightness = prefs.getDouble(_kBrightness) ?? 0.7;
      _contrast = prefs.getDouble(_kContrast) ?? 0.6;
      _volume = prefs.getDouble(_kVolume) ?? 0.8;
      _muted = prefs.getBool(_kMuted) ?? false;
      _soundEffects = prefs.getBool(_kSoundEffects) ?? true;
      _parentalControl = prefs.getBool(_kParentalControl) ?? false;
    });
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value.clamp(0.0, 1.0));
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _focusSelectedMenuItem() {
    if (!mounted) return;
    final i = _selectedIndex.clamp(0, _menuNodes.length - 1);
    _menuNodes[i].requestFocus();
  }

  void _openDetailsPanel(int i) {
    if (_selectedIndex != i) {
      setState(() => _selectedIndex = i);
    }
    _rightPanelScope.requestFocus();
  }

  @override
  void dispose() {
    _rightPanelScope.dispose();
    for (final n in _menuNodes) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final items = _buildItems(l);

    return Container(
      color: const Color(0xFF0A0A0F),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: settings list
          Container(
            width: 280,
            color: const Color(0xFF0D0D14),
            foregroundDecoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
                  child: Text(
                    l.t('settings_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return Focus(
                        focusNode: _menuNodes[i],
                        onFocusChange: (hasFocus) {
                          if (hasFocus && _selectedIndex != i) {
                            setState(() => _selectedIndex = i);
                          }
                        },
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent || event is KeyUpEvent) {
                            if (_isTvActivateEvent(event)) {
                              _openDetailsPanel(i);
                              return KeyEventResult.handled;
                            }
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowRight) {
                              _openDetailsPanel(i);
                              return KeyEventResult.handled;
                            }
                            if (event is KeyDownEvent &&
                                event.logicalKey ==
                                    LogicalKeyboardKey.arrowLeft) {
                              widget.onExitToSidebar();
                              return KeyEventResult.handled;
                            }
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (bctx) {
                            final focused = Focus.of(bctx).hasFocus;
                            final selected = _selectedIndex == i;
                            return GestureDetector(
                              onTap: () => _openDetailsPanel(i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 3,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: focused
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : selected
                                      ? const Color(
                                          0xFF6C63FF,
                                        ).withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: focused
                                        ? const Color(0xFF6C63FF)
                                        : selected
                                        ? const Color(
                                            0xFF6C63FF,
                                          ).withValues(alpha: 0.5)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.$1,
                                      color: focused || selected
                                          ? const Color(0xFF6C63FF)
                                          : Colors.white.withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      item.$2,
                                      style: TextStyle(
                                        color: focused || selected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                        fontSize: 15,
                                        fontWeight: focused || selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (selected)
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF6C63FF),
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Right: detail panel
          Expanded(
            child: FocusScope(
              node: _rightPanelScope,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  _focusSelectedMenuItem();
                  return KeyEventResult.handled;
                }
                if (isTvBackEvent(event)) {
                  _focusSelectedMenuItem();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: _buildDetailPanel(context, l),
            ),
          ),
        ],
      ),
    );
  }

  List<(IconData, String)> _buildItems(LocaleProvider l) => [
    (Icons.account_circle_outlined, l.t('settings_profile')),
    (Icons.display_settings_outlined, l.t('settings_display')),
    (Icons.volume_up_outlined, l.t('settings_sound')),
    (Icons.wifi_outlined, l.t('settings_network')),
    (Icons.language_outlined, l.t('settings_language')),
    (Icons.security_outlined, l.t('settings_privacy')),
    (Icons.info_outline, l.t('settings_about')),
  ];

  Widget _buildDetailPanel(BuildContext context, LocaleProvider l) {
    switch (_selectedIndex) {
      case 0:
        return _buildProfile(context, l);
      case 1:
        return _buildDisplay(context, l);
      case 2:
        return _buildSound(context, l);
      case 3:
        return _buildNetwork(l);
      case 4:
        return _buildLanguage(context, l);
      case 5:
        return _buildPrivacy(context, l);
      case 6:
        return _buildAbout(l);
      default:
        return const SizedBox();
    }
  }

  // ── Profile ──────────────────────────────────────────────────────────────────
  Widget _buildProfile(BuildContext context, LocaleProvider l) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : l.t('settings_profile_name_val');
    final email = user?.email ?? l.t('settings_profile_email_none');

    return _PanelScaffold(
      icon: Icons.account_circle_outlined,
      title: l.t('settings_profile'),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
              border: Border.all(color: const Color(0xFF6C63FF), width: 2),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          _InfoRow(label: l.t('settings_profile_name'), value: displayName),
          _InfoRow(label: l.t('settings_profile_email'), value: email),
          _InfoRow(
            label: l.t('settings_profile_plan'),
            value: auth.isSignedIn
                ? l.t('settings_profile_plan_val')
                : l.t('settings_profile_plan_guest'),
          ),
          const SizedBox(height: 14),
          Focus(
            onKeyEvent: (node, event) {
              if (_isTvActivateEvent(event)) {
                _handleAuthAction(context, l, auth);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Builder(
              builder: (ctx) {
                final focused = Focus.of(ctx).hasFocus;
                return GestureDetector(
                  onTap: () => _handleAuthAction(context, l, auth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: focused
                          ? Colors.white
                          : const Color(0xFF6C63FF).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: focused
                            ? Colors.white
                            : const Color(0xFF6C63FF).withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          auth.isSignedIn ? Icons.logout : Icons.login,
                          color: focused
                              ? Colors.black
                              : const Color(0xFF6C63FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          auth.isBusy
                              ? l.t('settings_profile_login_busy')
                              : auth.isSignedIn
                              ? l.t('settings_profile_logout')
                              : l.t('settings_profile_login'),
                          style: TextStyle(
                            color: focused
                                ? Colors.black
                                : const Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (auth.isAdmin && isAdminSupportedPlatform(context)) ...[
            const SizedBox(height: 12),
            Focus(
              onKeyEvent: (node, event) {
                if (_isTvActivateEvent(event)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminScreen()),
                  );
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (ctx) {
                  final focused = Focus.of(ctx).hasFocus;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminScreen()),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: focused
                            ? Colors.white
                            : const Color(0xFF00C853).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: focused
                              ? Colors.white
                              : const Color(0xFF00C853).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            color: focused
                                ? Colors.black
                                : const Color(0xFF00C853),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              color: focused
                                  ? Colors.black
                                  : const Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAuthAction(
    BuildContext context,
    LocaleProvider l,
    AuthProvider auth,
  ) async {
    if (auth.isBusy) return;

    if (auth.isSignedIn) {
      await auth.signOut();
    } else {
      await auth.signIn();
    }

    if (!context.mounted) return;

    final err = auth.error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.t('settings_profile_auth_error')),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      auth.clearError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.isSignedIn
              ? l.t('settings_profile_signed_in')
              : l.t('settings_profile_signed_out'),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  // ── Display ───────────────────────────────────────────────────────────────────
  Widget _buildDisplay(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.display_settings_outlined,
      title: l.t('settings_display'),
      child: Column(
        children: [
          _SliderRow(
            label: l.t('settings_display_brightness'),
            icon: Icons.brightness_6_outlined,
            value: _brightness,
            onChanged: (v) => setState(() => _brightness = v),
            onSaved: () {
              unawaited(_saveDouble(_kBrightness, _brightness));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _SliderRow(
            label: l.t('settings_display_contrast'),
            icon: Icons.contrast,
            value: _contrast,
            onChanged: (v) => setState(() => _contrast = v),
            onSaved: () {
              unawaited(_saveDouble(_kContrast, _contrast));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: l.t('settings_display_theme'),
            value: l.t('settings_display_theme_dark'),
          ),
        ],
      ),
    );
  }

  // ── Sound ─────────────────────────────────────────────────────────────────────
  Widget _buildSound(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.volume_up_outlined,
      title: l.t('settings_sound'),
      child: Column(
        children: [
          _SliderRow(
            label: l.t('settings_sound_volume'),
            icon: _muted ? Icons.volume_off : Icons.volume_up,
            value: _muted ? 0 : _volume,
            onChanged: _muted ? null : (v) => setState(() => _volume = v),
            onSaved: () {
              unawaited(_saveDouble(_kVolume, _volume));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          _ToggleRow(
            label: l.t('settings_sound_mute'),
            icon: Icons.volume_off_outlined,
            value: _muted,
            onChanged: (v) {
              setState(() => _muted = v);
              unawaited(_saveBool(_kMuted, v));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 12),
          _ToggleRow(
            label: l.t('settings_sound_effects'),
            icon: Icons.music_note_outlined,
            value: _soundEffects,
            onChanged: (v) {
              setState(() => _soundEffects = v);
              unawaited(_saveBool(_kSoundEffects, v));
              _showSaved(context, l);
            },
          ),
        ],
      ),
    );
  }

  // ── Network ───────────────────────────────────────────────────────────────────
  Widget _buildNetwork(LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.wifi_outlined,
      title: l.t('settings_network'),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.wifi, color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 12),
              Text(
                l.t('settings_network_connected'),
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(
            label: l.t('settings_network_type'),
            value: l.t('settings_network_type_val'),
          ),
          _InfoRow(
            label: l.t('settings_network_speed'),
            value: l.t('settings_network_speed_val'),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.75,
              backgroundColor: Color(0xFF2A2A3E),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '75%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language ─────────────────────────────────────────────────────────────────
  Widget _buildLanguage(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.language_outlined,
      title: l.t('settings_language'),
      child: Column(
        children: [
          _LangTile(
            code: 'uz',
            label: l.t('lang_uz'),
            flag: '🇺🇿',
            current: l.locale,
          ),
          const SizedBox(height: 10),
          _LangTile(
            code: 'ru',
            label: l.t('lang_ru'),
            flag: '🇷🇺',
            current: l.locale,
          ),
          const SizedBox(height: 10),
          _LangTile(
            code: 'en',
            label: l.t('lang_en'),
            flag: '🇬🇧',
            current: l.locale,
          ),
        ],
      ),
    );
  }

  // ── Privacy ───────────────────────────────────────────────────────────────────
  Widget _buildPrivacy(BuildContext context, LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.security_outlined,
      title: l.t('settings_privacy'),
      child: Column(
        children: [
          _ToggleRow(
            label: l.t('settings_privacy_parental'),
            icon: Icons.child_care_outlined,
            value: _parentalControl,
            onChanged: (v) {
              setState(() => _parentalControl = v);
              unawaited(_saveBool(_kParentalControl, v));
              _showSaved(context, l);
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF6C63FF), size: 22),
              const SizedBox(width: 12),
              Text(
                l.t('settings_privacy_history'),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              const Spacer(),
              Focus(
                onKeyEvent: (node, event) {
                  if (_isTvActivateEvent(event)) {
                    _clearHistory(context, l);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Builder(
                  builder: (bctx) {
                    final focused = Focus.of(bctx).hasFocus;
                    return GestureDetector(
                      onTap: () => _clearHistory(context, l),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: focused
                              ? Colors.red
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: focused
                                ? Colors.red
                                : Colors.red.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _historyCleared
                              ? '✓'
                              : l.t('settings_privacy_history_clear'),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── About ─────────────────────────────────────────────────────────────────────
  Widget _buildAbout(LocaleProvider l) {
    return _PanelScaffold(
      icon: Icons.info_outline,
      title: l.t('settings_about'),
      child: Column(
        children: [
          const Center(
            child: Column(
              children: [
                Icon(Icons.tv, color: Color(0xFF6C63FF), size: 56),
                SizedBox(height: 8),
                Text(
                  'SMART TV',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoRow(label: l.t('settings_about_version'), value: '1.0.0'),
          _InfoRow(label: l.t('settings_about_build'), value: '2026.05.12'),
          _InfoRow(
            label: l.t('settings_about_developer'),
            value: l.t('settings_about_developer_val'),
          ),
          _InfoRow(
            label: l.t('settings_about_license'),
            value: l.t('settings_about_license_val'),
          ),
        ],
      ),
    );
  }

  void _showSaved(BuildContext context, LocaleProvider l) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('settings_saved')),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _clearHistory(BuildContext context, LocaleProvider l) {
    context.read<FavoritesProvider>().clearWatchHistory();
    setState(() => _historyCleared = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _historyCleared = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.t('settings_privacy_history_cleared')),
        backgroundColor: const Color(0xFF6C63FF),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Settings Helper Widgets ──────────────────────────────────────────────────

class _PanelScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _PanelScaffold({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6C63FF), size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isTvActivateEvent(KeyEvent event) => isTvActivateEvent(event);

class _SliderRow extends StatefulWidget {
  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double>? onChanged;
  final VoidCallback onSaved;
  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.onSaved,
  });

  @override
  State<_SliderRow> createState() => _SliderRowState();
}

class _SliderRowState extends State<_SliderRow> {
  static const double _step = 0.05;
  bool _isEditing = false;

  bool get _isEnabled => widget.onChanged != null;

  void _setEditing(bool value, {bool save = false}) {
    if (_isEditing == value) return;
    setState(() => _isEditing = value);
    if (save) widget.onSaved();
  }

  void _changeBy(double delta) {
    if (!_isEnabled) return;
    final next = (widget.value + delta).clamp(0.0, 1.0);
    if (next != widget.value) {
      widget.onChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && _isEditing) {
          _setEditing(false, save: true);
        }
      },
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          if (!_isEnabled) return KeyEventResult.handled;
          if (_isEditing) {
            _setEditing(false, save: true);
          } else {
            _setEditing(true);
          }
          return KeyEventResult.handled;
        }

        if (event is KeyDownEvent && _isEditing) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _changeBy(_step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _changeBy(-_step);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _setEditing(false, save: true);
            return KeyEventResult.ignored;
          }
        }

        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          final active = focused || _isEditing;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isEditing
                    ? const Color(0xFF6C63FF)
                    : focused
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: const Color(0xFF6C63FF), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '${(widget.value * 100).round()}%',
                      style: TextStyle(
                        color: _isEditing
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: _isEditing
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                ExcludeFocus(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF6C63FF),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                      thumbColor: const Color(0xFF6C63FF),
                      overlayColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: widget.value,
                      onChanged: widget.onChanged,
                      onChangeEnd: (_) => widget.onSaved(),
                    ),
                  ),
                ),
                if (focused)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _isEditing ? 'ENTER - Save' : 'ENTER - Edit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          onChanged(!value);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: focused
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: focused
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: value
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  ExcludeFocus(
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeThumbColor: const Color(0xFF6C63FF),
                      activeTrackColor: const Color(
                        0xFF6C63FF,
                      ).withValues(alpha: 0.4),
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

class _LangTile extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final String current;
  const _LangTile({
    required this.code,
    required this.label,
    required this.flag,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = code == current;
    return Focus(
      autofocus: isSelected,
      onKeyEvent: (node, event) {
        if (_isTvActivateEvent(event)) {
          _select(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (ctx) {
          final focused = Focus.of(ctx).hasFocus;
          return GestureDetector(
            onTap: () => _select(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.18)
                    : focused
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : focused
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF6C63FF),
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _select(BuildContext context) {
    Provider.of<LocaleProvider>(context, listen: false).setLocale(code);
  }
}
