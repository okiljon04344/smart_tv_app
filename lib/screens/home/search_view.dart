import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/content.dart';
import '../../services/locale_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/content_card.dart';
import '../../widgets/tv_focusable.dart';

const _popularTags = [
  'Sci-Fi',
  'Drama',
  'Animation',
  'Comedy',
  'Horror',
  'Sport',
];

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  void _searchFor(String tag) {
    _controller.text = tag;
    setState(() => _query = tag);
  }

  @override
  Widget build(BuildContext context) {
    final l = Provider.of<LocaleProvider>(context);
    final colors = context.colors;
    final results = _results;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.t('search_title'), style: context.text.headlineMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            style: context.text.bodyLarge,
            decoration: InputDecoration(
              hintText: l.t('search_hint'),
              prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 32),
          if (_query.isEmpty) ...[
            Text(
              l.t('search_popular_tags'),
              style: context.text.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tag in _popularTags)
                  TvFocusable(
                    onActivate: () => _searchFor(tag),
                    builder: (context, focused) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      foregroundDecoration: focusRing(colors, focused),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                        border: Border.all(color: colors.outline),
                      ),
                      child: Text(tag, style: context.text.labelLarge),
                    ),
                  ),
              ],
            ),
          ] else ...[
            Text(
              l.t('search_results', n: '${results.length}'),
              style: context.text.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: ContentCard.rowHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: results.length,
                itemBuilder: (ctx, i) =>
                    ContentCard(content: results[i], autofocus: i == 0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
