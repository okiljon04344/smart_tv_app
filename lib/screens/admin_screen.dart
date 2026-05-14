import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_provider.dart';

bool isAdminSupportedPlatform(BuildContext context) {
  if (kIsWeb) {
    return true;
  }

  final platform = defaultTargetPlatform;
  if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
    final size = MediaQuery.of(context).size;
    // Keep admin access for phone-sized layouts only; block TV/tablet screens.
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
          backgroundColor: const Color(0xFF1B1D2D),
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
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: Text(
            'Admin panel faqat admin account va telefon/chrome uchun.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF141624),
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
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Xatolik: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final value = snapshot.data?.snapshot.value;
          if (value is! Map || value.isEmpty) {
            return const Center(
              child: Text(
                'Video topilmadi',
                style: TextStyle(color: Colors.white70),
              ),
            );
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
                title: Text(
                  '${map['title'] ?? 'Video'} (#$id)',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${map['genre'] ?? ''} • ${map['year'] ?? ''}',
                  style: const TextStyle(color: Colors.white60),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white70),
                      onPressed: () => _upsertVideo(existing: map),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
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
