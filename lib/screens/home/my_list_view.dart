import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/sample_data.dart';
import '../../services/locale_provider.dart';
import '../../services/favorites_provider.dart';
import '../../widgets/content_card.dart';

// ─── My List Screen ───────────────────────────────────────────────────────────

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

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
