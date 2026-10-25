import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/content.dart';
import '../../services/favorites_provider.dart';
import '../../services/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_card.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final favorites = context.watch<FavoritesProvider>();
    final colors = context.colors;
    final all = allContent;
    final favList = favorites.getFavorites(all);
    final continueList = favorites.getContinueWatching(all);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.t('nav_my_list'), style: context.text.headlineMedium),
          const SizedBox(height: 24),
          Expanded(
            child: favList.isEmpty && continueList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.t('my_list_empty'),
                          style: context.text.bodyLarge?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      if (continueList.isNotEmpty) ...[
                        _Section(
                          title: l.t('continue_watching'),
                          items: continueList,
                          autofocusFirst: true,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (favList.isNotEmpty)
                        _Section(
                          title: l.t('my_favorites'),
                          items: favList,
                          autofocusFirst: continueList.isEmpty,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Content> items;
  final bool autofocusFirst;

  const _Section({
    required this.title,
    required this.items,
    required this.autofocusFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: ContentCard.rowHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (ctx, i) => ContentCard(
              content: items[i],
              autofocus: autofocusFirst && i == 0,
            ),
          ),
        ),
      ],
    );
  }
}
