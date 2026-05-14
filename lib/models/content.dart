class Content {
  final String id;
  final String title;
  final String subtitle;
  final String genre;
  final String year;
  final String rating;
  final String duration;
  final int colorCode;
  final String? youtubeUrl;
  final bool isNew;
  final bool isHD;

  const Content({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.genre,
    required this.year,
    required this.rating,
    required this.duration,
    required this.colorCode,
    this.youtubeUrl,
    this.isNew = false,
    this.isHD = true,
  });
}

class Category {
  final String name;
  final List<Content> items;

  const Category({required this.name, required this.items});
}
