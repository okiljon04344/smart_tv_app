import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../data/sample_data.dart';

class CatalogProvider extends ChangeNotifier {
  final DatabaseReference _moviesRef = FirebaseDatabase.instance.ref('movies');
  final DatabaseReference _categoriesRef = FirebaseDatabase.instance.ref(
    'categories',
  );

  StreamSubscription<DatabaseEvent>? _moviesSub;
  StreamSubscription<DatabaseEvent>? _categoriesSub;

  Object? _moviesRaw;
  Object? _categoriesRaw;

  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  Future<void> init() async {
    await refresh();
    _startListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final moviesSnap = await _moviesRef.get();
      final categoriesSnap = await _categoriesRef.get();
      _moviesRaw = moviesSnap.value;
      _categoriesRaw = categoriesSnap.value;

      final parsed = parseCatalogFromRealtime(_moviesRaw, _categoriesRaw);
      if (parsed.isNotEmpty) {
        categories = parsed;
      }

      _isOffline = false;
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isOffline = true;
      _error = e.toString();
      notifyListeners();
    }
  }

  void _startListeners() {
    _moviesSub?.cancel();
    _categoriesSub?.cancel();

    _moviesSub = _moviesRef.onValue.listen(
      (event) {
        _moviesRaw = event.snapshot.value;
        _applyLiveUpdate();
      },
      onError: (Object e) {
        _isOffline = true;
        _error = e.toString();
        notifyListeners();
      },
    );

    _categoriesSub = _categoriesRef.onValue.listen(
      (event) {
        _categoriesRaw = event.snapshot.value;
        _applyLiveUpdate();
      },
      onError: (Object e) {
        _isOffline = true;
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  void _applyLiveUpdate() {
    final parsed = parseCatalogFromRealtime(_moviesRaw, _categoriesRaw);
    if (parsed.isEmpty) return;

    categories = parsed;
    _isLoading = false;
    _isOffline = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _moviesSub?.cancel();
    _categoriesSub?.cancel();
    super.dispose();
  }
}
