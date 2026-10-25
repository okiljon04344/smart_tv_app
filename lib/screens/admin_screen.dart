import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

bool isAdminSupportedPlatform(BuildContext context) {
  if (kIsWeb) {
    return true;
  }

  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
    final size = MediaQuery.of(context).size;
    // Phone-sized layouts only; TV and tablet screens are blocked.
    return size.width < 600 && size.shortestSide < 600;
  }
  return false;
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseReference _moviesRef = FirebaseDatabase.instance.ref('movies');

  Future<void> _upsertVideo({Map? existing}) async {
    final idCtrl = TextEditingController(
      text: existing?['id']?.toString() ?? '',
    );
    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );
    final genreCtrl = TextEditingController(
      text: existing?['genre']?.toString() ?? 'General',
    );
    final yearCtrl = TextEditingController(
      text: existing?['year']?.toString() ?? '2025',
    );
    final ratingCtrl = TextEditingController(
      text: existing?['rating']?.toString() ?? '8.0',
    );
    final durationCtrl = TextEditingController(
      text: existing?['duration']?.toString() ?? '1:30',
    );
    final subtitleCtrl = TextEditingController(
      text: existing?['subtitle']?.toString() ?? '',
    );
    final ytCtrl = TextEditingController(
      text: existing?['youtubeUrl']?.toString() ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing == null ? 'Add video' : 'Update video'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _f(idCtrl, 'ID'),
                  _f(titleCtrl, 'Title'),
                  _f(subtitleCtrl, 'Subtitle'),
                  _f(genreCtrl, 'Genre'),
                  _f(yearCtrl, 'Year'),
                  _f(ratingCtrl, 'Rating'),
                  _f(durationCtrl, 'Duration (1:30)'),
                  _f(ytCtrl, 'YouTube URL'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }
    final id = idCtrl.text.trim();
    if (id.isEmpty ||
        titleCtrl.text.trim().isEmpty ||
        ytCtrl.text.trim().isEmpty) {
      return;
    }

    await _moviesRef.child(id).update({
      'id': id,
      'title': titleCtrl.text.trim(),
      'subtitle': subtitleCtrl.text.trim().isEmpty
          ? '${genreCtrl.text.trim()}, TV'
          : subtitleCtrl.text.trim(),
      'genre': genreCtrl.text.trim(),
      'year': yearCtrl.text.trim(),
      'rating': ratingCtrl.text.trim(),
      'duration': durationCtrl.text.trim(),
      'youtubeUrl': ytCtrl.text.trim(),
      'isHD': true,
      'isNew': false,
      'colorCode': existing?['colorCode'] ?? 0xFF1A237E,
    });
  }

  Future<void> _deleteVideo(String id) async {
    await _moviesRef.child(id).remove();
  }

  Widget _f(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final allowed = auth.isAdmin && isAdminSupportedPlatform(context);

    if (!allowed) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Admin panel faqat admin account va telefon/chrome uchun.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            onPressed: () => _upsertVideo(),
            icon: const Icon(Icons.add),
            tooltip: 'Add video',
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _moviesRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Xatolik: ${snapshot.error}',
                style: TextStyle(color: context.colors.error),
              ),
            );
          }

          final value = snapshot.data?.snapshot.value;
          if (value is! Map || value.isEmpty) {
            return const Center(child: Text('Video topilmadi'));
          }

          final entries =
              value.entries
                  .map((e) => MapEntry(e.key.toString(), e.value))
                  .toList()
                ..sort((a, b) => a.key.compareTo(b.key));

          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final id = entries[index].key;
              final raw = entries[index].value;
              final map = raw is Map
                  ? raw.map((k, v) => MapEntry(k.toString(), v))
                  : <String, Object?>{};
              return ListTile(
                title: Text('${map['title'] ?? 'Video'} (#$id)'),
                subtitle: Text(
                  '${map['genre'] ?? ''} \u00b7 ${map['year'] ?? ''}',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _upsertVideo(existing: map),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: context.colors.error,
                      ),
                      onPressed: () => _deleteVideo(id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
