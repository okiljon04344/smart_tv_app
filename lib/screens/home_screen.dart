import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/content.dart';
import '../services/catalog_provider.dart';
import '../services/locale_provider.dart';
import '../utils/tv_key_helper.dart';
import 'home/browse_view.dart';
import 'home/my_list_view.dart';
import 'home/search_view.dart';
import 'home/settings_view.dart';
import 'home/sidebar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentScope.requestFocus();
    });
  }

  List<NavItemData> _buildNavItems(LocaleProvider l) => [
    NavItemData(Icons.home_rounded, l.t('nav_home')),
    NavItemData(Icons.movie_outlined, l.t('nav_movies')),
    NavItemData(Icons.live_tv_outlined, l.t('nav_series')),
    NavItemData(Icons.stream, l.t('nav_live')),
    NavItemData(Icons.favorite_border, l.t('nav_my_list')),
    NavItemData(Icons.search, l.t('nav_search')),
    NavItemData(Icons.settings_outlined, l.t('nav_settings')),
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
      return const CatalogLoadingView();
    }
    if (showCatalogState && catalog.error != null && categories.isEmpty) {
      return CatalogErrorView(onRetry: catalog.refresh);
    }

    switch (_selectedNavIndex) {
      case 4:
        return const MyListScreen();
      case 5:
        return const SearchScreen();
      case 6:
        return SettingsScreen(
          onExitToSidebar: () => _sidebarScope.requestFocus(),
        );
      default:
        return MainContent(
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
      body: Row(
        children: [
          FocusScope(
            node: _sidebarScope,
            child: Sidebar(
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
                // The key makes autofocus run again when the section changes.
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
