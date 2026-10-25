import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/sample_data.dart';
import '../../models/content.dart';
import '../../services/locale_provider.dart';
import '../../utils/tv_key_helper.dart';
import '../../widgets/content_card.dart';

// ─── Search Screen ────────────────────────────────────────────────────────────

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
