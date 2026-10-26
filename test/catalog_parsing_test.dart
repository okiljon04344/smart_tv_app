import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_tv_app/data/sample_data.dart';

void main() {
  group('parseCatalogFromRealtime', () {
    test('returns an empty list when input is not a map', () {
      expect(parseCatalogFromRealtime(null, null), isEmpty);
      expect(parseCatalogFromRealtime(<String, Object?>{}, 'x'), isEmpty);
    });

    test('maps movies into categories and applies defaults', () {
      final movies = {
        '1': {'id': '1', 'title': 'A', 'colorCode': 123, 'isNew': true},
        '2': {'title': 'B', 'colorCode': '456', 'isHD': false},
      };
      final cats = {
        'c1': {
          'name': 'First',
          'items': ['1', '2', 'missing'],
        },
      };

      final parsed = parseCatalogFromRealtime(movies, cats);

      expect(parsed, hasLength(1));
      expect(parsed.first.name, 'First');
      // Unknown ids are skipped.
      expect(parsed.first.items.map((c) => c.id), ['1', '2']);
      expect(parsed.first.items[0].colorCode, 123);
      expect(parsed.first.items[0].isNew, isTrue);
      expect(parsed.first.items[0].isHD, isTrue);
      // The map key is used when `id` is missing; string colors are parsed.
      expect(parsed.first.items[1].colorCode, 456);
      expect(parsed.first.items[1].isHD, isFalse);
    });

    test('accepts the map form of category items', () {
      final movies = {
        '1': {'id': '1', 'title': 'A'},
        '2': {'id': '2', 'title': 'B'},
      };
      final cats = {
        'c1': {
          'name': 'Map form',
          'items': {'1': true, '2': false},
        },
      };

      final parsed = parseCatalogFromRealtime(movies, cats);

      expect(parsed.single.items.map((c) => c.id), ['1']);
    });

    test('parses the bundled seed JSON files', () {
      final movies =
          jsonDecode(File('seed/movies.json').readAsStringSync()) as Object?;
      final cats =
          jsonDecode(File('seed/categories.json').readAsStringSync())
              as Object?;

      final parsed = parseCatalogFromRealtime(movies, cats);

      expect(parsed, isNotEmpty);
      for (final category in parsed) {
        expect(category.items, isNotEmpty);
        for (final item in category.items) {
          expect(item.id, isNotEmpty);
          expect(item.title, isNotEmpty);
        }
      }
    });
  });
}
