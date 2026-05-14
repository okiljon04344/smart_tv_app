import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class FavoritesProvider extends ChangeNotifier {
  static const _favoritesKey = 'favorite_ids';
  static const _progressKey = 'watch_progress';

  final Set<String> _favoriteIds = {};
  final Map<String, double> _watchProgress = {};

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;
  User? get _currentUser =>
      _isFirebaseReady ? FirebaseAuth.instance.currentUser : null;

  DatabaseReference? get _favoritesRef {
    final user = _currentUser;
    if (user == null) return null;
    return FirebaseDatabase.instance.ref('users/${user.uid}/favorites');
  }

  Future<void> init({Map<String, double>? initialProgress}) async {
    final prefs = await SharedPreferences.getInstance();

    final storedFavs = prefs.getStringList(_favoritesKey) ?? const [];
    _favoriteIds
      ..clear()
      ..addAll(storedFavs);

    _watchProgress.clear();
    final rawProgress = prefs.getString(_progressKey);
    if (rawProgress != null && rawProgress.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawProgress) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is num) {
            _watchProgress[key] = value.toDouble().clamp(0.0, 1.0);
          }
        });
      } catch (_) {
        // Ignore corrupted data and continue with defaults.
      }
    }

    if (_watchProgress.isEmpty && initialProgress != null) {
      _watchProgress.addAll(
        initialProgress.map((k, v) => MapEntry(k, v.clamp(0.0, 1.0))),
      );
      unawaited(_persistProgress());
    }

    await _tryLoadRemoteFavorites();

    notifyListeners();
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteIds.toList());
    unawaited(_syncFavoritesToCloud());
  }

  Future<void> _persistProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(_watchProgress));
  }

  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(Content content) {
    if (_favoriteIds.contains(content.id)) {
      _favoriteIds.remove(content.id);
    } else {
      _favoriteIds.add(content.id);
    }
    unawaited(_persistFavorites());
    notifyListeners();
  }

  Future<void> _tryLoadRemoteFavorites() async {
    final ref = _favoritesRef;
    if (ref == null) return;
    try {
      final snap = await ref.get();
      if (!snap.exists || snap.value == null) return;
      final raw = snap.value;
      if (raw is Map) {
        final remoteIds = <String>{};
        raw.forEach((key, value) {
          if (value == true) {
            remoteIds.add(key.toString());
          }
        });
        if (remoteIds.isNotEmpty) {
          _favoriteIds
            ..clear()
            ..addAll(remoteIds);
          await _persistFavorites();
        }
      }
    } catch (_) {
      // Remote sync is best-effort; keep local data if cloud read fails.
    }
  }

  Future<void> _syncFavoritesToCloud() async {
    final ref = _favoritesRef;
    if (ref == null) return;
    try {
      final payload = <String, bool>{for (final id in _favoriteIds) id: true};
      await ref.set(payload);
    } catch (_) {
      // Keep app functional offline or when DB permissions/network fail.
    }
  }

  List<Content> getFavorites(List<Content> allContent) =>
      allContent.where((c) => _favoriteIds.contains(c.id)).toList();

  double getProgress(String id) => _watchProgress[id] ?? 0.0;

  void setProgress(String id, double progress) {
    final normalized = progress.clamp(0.0, 1.0);
    if (normalized <= 0.0) {
      _watchProgress.remove(id);
    } else {
      _watchProgress[id] = normalized;
    }
    unawaited(_persistProgress());
    notifyListeners();
  }

  void clearWatchHistory() {
    _watchProgress.clear();
    unawaited(_persistProgress());
    notifyListeners();
  }

  List<Content> getContinueWatching(List<Content> allContent) {
    return allContent.where((c) {
      final p = _watchProgress[c.id] ?? 0.0;
      return p > 0.0 && p < 1.0;
    }).toList();
  }
}
