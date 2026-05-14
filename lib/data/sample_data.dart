import 'package:firebase_database/firebase_database.dart';

import '../models/content.dart';

List<Category> categories = [
  Category(
    name: 'cat_popular',
    items: [
      Content(
        id: '1',
        title: 'Galaktika Sargardoni',
        subtitle: 'Sci-Fi, Sarguzasht',
        genre: 'Sci-Fi',
        year: '2024',
        rating: '8.9',
        duration: '2s 18d',
        colorCode: 0xFF1A237E,
        youtubeUrl: 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
        isHD: true,
      ),
      Content(
        id: '2',
        title: 'Tog\' Shahri',
        subtitle: 'Dram, Triller',
        genre: 'Drama',
        year: '2023',
        rating: '8.2',
        duration: '1s 54d',
        colorCode: 0xFF880E4F,
        isHD: true,
      ),
      Content(
        id: '3',
        title: 'Qorong\'lik Oroli',
        subtitle: 'Mistika, Horror',
        genre: 'Horror',
        year: '2024',
        rating: '7.8',
        duration: '1s 42d',
        colorCode: 0xFF1B5E20,
      ),
      Content(
        id: '4',
        title: 'Yulduz Yo\'li',
        subtitle: 'Animatsiya, Oilaviy',
        genre: 'Animation',
        year: '2025',
        rating: '9.1',
        duration: '1s 35d',
        colorCode: 0xFFE65100,
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '5',
        title: 'Shamol Shahri',
        subtitle: 'Romantik, Komediya',
        genre: 'Comedy',
        year: '2023',
        rating: '7.5',
        duration: '1s 48d',
        colorCode: 0xFF4A148C,
      ),
      Content(
        id: '6',
        title: 'Dengiz Tubida',
        subtitle: 'Sarguzasht, Sci-Fi',
        genre: 'Adventure',
        year: '2024',
        rating: '8.5',
        duration: '2s 5d',
        colorCode: 0xFF006064,
        isHD: true,
      ),
      Content(
        id: '25',
        title: 'Vaqt Mashinasi',
        subtitle: 'Sci-Fi, Sarguzasht',
        genre: 'Sci-Fi',
        year: '2025',
        rating: '9.2',
        duration: '2s 45d',
        colorCode: 0xFF0D47A1,
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '26',
        title: 'Osmon Chegarasi',
        subtitle: 'Action, Triller',
        genre: 'Action',
        year: '2025',
        rating: '8.6',
        duration: '1s 58d',
        colorCode: 0xFF37474F,
        isNew: true,
        isHD: true,
      ),
    ],
  ),
  Category(
    name: 'cat_series',
    items: [
      Content(
        id: '7',
        title: 'Poytaxt Siri',
        subtitle: 'Dram, Kriminal',
        genre: 'Drama',
        year: '2024',
        rating: '9.3',
        duration: 'Mavsum 3',
        colorCode: 0xFF3E2723,
        youtubeUrl: 'https://youtu.be/5PSNL1qE6VY',
        isHD: true,
      ),
      Content(
        id: '8',
        title: 'Kelajak Odamlari',
        subtitle: 'Sci-Fi, Dram',
        genre: 'Sci-Fi',
        year: '2025',
        rating: '8.7',
        duration: 'Mavsum 2',
        colorCode: 0xFF0D47A1,
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '9',
        title: 'Komediya Klubi',
        subtitle: 'Komediya, Shou',
        genre: 'Comedy',
        year: '2025',
        rating: '8.0',
        duration: 'Mavsum 5',
        colorCode: 0xFF558B2F,
        isHD: true,
      ),
      Content(
        id: '10',
        title: 'Tarix Saboqlari',
        subtitle: 'Tarixiy, Dram',
        genre: 'Historical',
        year: '2023',
        rating: '8.4',
        duration: 'Mavsum 1',
        colorCode: 0xFF6A1B9A,
      ),
      Content(
        id: '11',
        title: 'Zamonaviy Hayot',
        subtitle: 'Komediya, Oilaviy',
        genre: 'Family',
        year: '2024',
        rating: '7.9',
        duration: 'Mavsum 4',
        colorCode: 0xFF00695C,
        isHD: true,
      ),
      Content(
        id: '12',
        title: 'Qo\'rqinch Uyi',
        subtitle: 'Horror, Mistika',
        genre: 'Horror',
        year: '2025',
        rating: '8.6',
        duration: 'Mavsum 2',
        colorCode: 0xFFB71C1C,
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '27',
        title: 'Temir Iroda',
        subtitle: 'Dram, Sport',
        genre: 'Drama',
        year: '2025',
        rating: '8.9',
        duration: 'Mavsum 1',
        colorCode: 0xFF4527A0,
        isNew: true,
        isHD: true,
      ),
    ],
  ),
  Category(
    name: 'cat_live',
    items: [
      Content(
        id: '13',
        title: 'Sport 1',
        subtitle: 'Futbol, Basketbol',
        genre: 'Sport',
        year: 'LIVE',
        rating: 'HD',
        duration: '24/7',
        colorCode: 0xFF1565C0,
        isHD: true,
      ),
      Content(
        id: '14',
        title: 'Yangiliklar 24',
        subtitle: 'Yangiliklar, Tahlil',
        genre: 'News',
        year: 'LIVE',
        rating: 'HD',
        duration: '24/7',
        colorCode: 0xFFC62828,
        isHD: true,
      ),
      Content(
        id: '15',
        title: 'Musiqa TV',
        subtitle: 'Pop, Rock, Jazz',
        genre: 'Music',
        year: 'LIVE',
        rating: 'HD',
        duration: '24/7',
        colorCode: 0xFF6A1B9A,
        isHD: true,
      ),
      Content(
        id: '16',
        title: 'Bolalar Kanali',
        subtitle: 'Animatsiya, Ta\'lim',
        genre: 'Kids',
        year: 'LIVE',
        rating: 'HD',
        duration: '24/7',
        colorCode: 0xFF2E7D32,
        isHD: true,
      ),
      Content(
        id: '17',
        title: 'Kino Premium',
        subtitle: 'Klassik Filmlar',
        genre: 'Cinema',
        year: 'LIVE',
        rating: 'HD',
        duration: '24/7',
        colorCode: 0xFF4E342E,
        isHD: true,
      ),
      Content(
        id: '18',
        title: 'Tabiat Dunyosi',
        subtitle: 'Hujjatli, Ilm',
        genre: 'Documentary',
        year: 'LIVE',
        rating: '4K',
        duration: '24/7',
        colorCode: 0xFF33691E,
        isHD: true,
      ),
    ],
  ),
  Category(
    name: 'cat_recommended',
    items: [
      Content(
        id: '19',
        title: 'Sahro Siri',
        subtitle: 'Tarixiy, Sarguzasht',
        genre: 'Adventure',
        year: '2025',
        rating: '9.0',
        duration: '2s 30d',
        colorCode: 0xFFF57F17,
        isHD: true,
      ),
      Content(
        id: '20',
        title: 'Neon Shahar',
        subtitle: 'Kiberpank, Action',
        genre: 'Action',
        year: '2025',
        rating: '8.8',
        duration: '1s 55d',
        colorCode: 0xFF880E4F,
        youtubeUrl: 'https://www.youtube.com/watch?v=ysz5S6PUM-U',
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '21',
        title: 'Muzli Tog\'lar',
        subtitle: 'Dram, Romantik',
        genre: 'Romance',
        year: '2024',
        rating: '7.7',
        duration: '1s 38d',
        colorCode: 0xFF01579B,
      ),
      Content(
        id: '22',
        title: 'Robot Inqilobi',
        subtitle: 'Sci-Fi, Action',
        genre: 'Sci-Fi',
        year: '2025',
        rating: '8.3',
        duration: '2s 10d',
        colorCode: 0xFF212121,
        isNew: true,
        isHD: true,
      ),
      Content(
        id: '23',
        title: 'Qadimgi Shahar',
        subtitle: 'Tarixiy, Komediya',
        genre: 'Historical',
        year: '2024',
        rating: '8.1',
        duration: '1s 50d',
        colorCode: 0xFF4E342E,
      ),
      Content(
        id: '24',
        title: 'Yashil Vodiy',
        subtitle: 'Dram, Oilaviy',
        genre: 'Family',
        year: '2023',
        rating: '8.6',
        duration: '1s 45d',
        colorCode: 0xFF1B5E20,
        isHD: true,
      ),
      Content(
        id: '28',
        title: 'Qorong\'u Dengiz',
        subtitle: 'Triller, Mistika',
        genre: 'Thriller',
        year: '2025',
        rating: '8.4',
        duration: '1s 52d',
        colorCode: 0xFF1A237E,
        isNew: true,
        isHD: true,
      ),
    ],
  ),
];

/// Barcha kontentlar ro'yxati (search va favorites uchun)
List<Content> get allContent => categories.expand((c) => c.items).toList();

/// Seansda ko'rilayotgan kontentlar (demo uchun dastlabki progress)
final Map<String, double> initialWatchProgress = {
  '1': 0.65,
  '7': 0.30,
  '19': 0.85,
  '8': 0.15,
};

Future<void> loadCatalogFromRealtime() async {
  try {
    final db = FirebaseDatabase.instance;
    final moviesSnap = await db.ref('movies').get();
    final categoriesSnap = await db.ref('categories').get();
    final parsed = parseCatalogFromRealtime(
      moviesSnap.value,
      categoriesSnap.value,
    );
    if (parsed.isNotEmpty) categories = parsed;
  } catch (_) {
    // Keep local fallback data if remote loading fails.
  }
}

List<Category> parseCatalogFromRealtime(
  Object? moviesRaw,
  Object? categoriesRaw,
) {
  if (moviesRaw is! Map || categoriesRaw is! Map) return const [];

  final byId = <String, Content>{};
  moviesRaw.forEach((key, value) {
    if (value is Map) {
      final map = value.map((k, v) => MapEntry(k.toString(), v));
      final id = (map['id'] ?? key).toString();
      byId[id] = Content(
        id: id,
        title: (map['title'] ?? '').toString(),
        subtitle: (map['subtitle'] ?? '').toString(),
        genre: (map['genre'] ?? '').toString(),
        year: (map['year'] ?? '').toString(),
        rating: (map['rating'] ?? '').toString(),
        duration: (map['duration'] ?? '').toString(),
        colorCode: (map['colorCode'] is num)
            ? (map['colorCode'] as num).toInt()
            : int.tryParse((map['colorCode'] ?? '0').toString()) ?? 0xFF1A237E,
        youtubeUrl: map['youtubeUrl']?.toString(),
        isNew: map['isNew'] == true,
        isHD: map['isHD'] != false,
      );
    }
  });

  final remoteCategories = <Category>[];
  categoriesRaw.forEach((key, value) {
    if (value is! Map) return;
    final map = value.map((k, v) => MapEntry(k.toString(), v));
    final name = (map['name'] ?? key).toString();
    final idsRaw = map['items'];
    final ids = <String>[];

    if (idsRaw is List) {
      for (final e in idsRaw) {
        ids.add(e.toString());
      }
    } else if (idsRaw is Map) {
      idsRaw.forEach((k, v) {
        if (v == true) ids.add(k.toString());
      });
    }

    final items = <Content>[];
    for (final id in ids) {
      final c = byId[id];
      if (c != null) items.add(c);
    }

    if (items.isNotEmpty) {
      remoteCategories.add(Category(name: name, items: items));
    }
  });

  return remoteCategories;
}
