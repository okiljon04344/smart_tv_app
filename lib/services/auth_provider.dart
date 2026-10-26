import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  /// Admin e-mail, injected at build time with
  /// `--dart-define=ADMIN_EMAIL=...`. Empty means no admin account is configured.
  static const String adminEmail = String.fromEnvironment('ADMIN_EMAIL');
  static const String tvAdminBlockedMessage =
      'Admin account TV qurilmada login qila olmaydi';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  User? _user;
  bool _isGuest = false;
  bool _isBusy = false;
  String? _error;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  DatabaseReference get _usersRef => FirebaseDatabase.instance.ref('users');

  bool get _isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isTvLikeDevice {
    if (!_isMobilePlatform) {
      return false;
    }
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return false;
    }
    final view = views.first;
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    return logicalSize.width >= 600 || logicalSize.shortestSide >= 600;
  }

  bool _isAdminEmail(String? email) {
    if (adminEmail.isEmpty) return false;
    return (email ?? '').trim().toLowerCase() == adminEmail.trim().toLowerCase();
  }

  bool _shouldBlockAdminOnTv(String? email) =>
      _isTvLikeDevice && _isAdminEmail(email);

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _user != null || _isGuest;
  bool get isAdmin => _isAdminEmail(_user?.email);
  String? get error => _error;

  void signInAsGuest() {
    _isGuest = true;
    _error = null;
    notifyListeners();
  }

  Future<void> init() async {
    _isBusy = true;
    notifyListeners();
    try {
      _user = _isFirebaseReady ? FirebaseAuth.instance.currentUser : null;
      if (_user != null && _shouldBlockAdminOnTv(_user?.email)) {
        if (_isFirebaseReady) {
          await FirebaseAuth.instance.signOut();
        }
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // Ignore Google sign-out issues for email/password users.
        }
        _user = null;
        _error = tvAdminBlockedMessage;
        return;
      }
      if (_user != null) {
        await _syncUserProfile(_user!, createDefaults: false);
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signIn() => signInWithGoogle();

  Future<void> signInWithGoogle() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      if (!_isFirebaseReady) {
        throw StateError('Firebase is not initialized');
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _error = 'Sign-in cancelled';
        return;
      }
      if (_shouldBlockAdminOnTv(googleUser.email)) {
        _error = tvAdminBlockedMessage;
        try {
          await _googleSignIn.signOut();
        } catch (_) {
          // Best effort to clear Google session.
        }
        if (_isFirebaseReady) {
          await FirebaseAuth.instance.signOut();
        }
        _user = null;
        return;
      }

      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      _user = userCredential.user;
      if (_user != null) {
        await _syncUserProfile(_user!, createDefaults: false);
      }
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      if (!_isFirebaseReady) {
        throw StateError('Firebase is not initialized');
      }

      if (_shouldBlockAdminOnTv(email)) {
        _error = tvAdminBlockedMessage;
        _user = null;
        return;
      }

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      _user = userCredential.user;
      if (_user != null) {
        await _syncUserProfile(_user!, createDefaults: false);
      }
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      if (!_isFirebaseReady) {
        throw StateError('Firebase is not initialized');
      }

      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      _user = userCredential.user;
      if (_user != null) {
        await _syncUserProfile(_user!, createDefaults: true);
      }
      _error = null;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? e.code;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isBusy) return;
    _isBusy = true;
    notifyListeners();
    try {
      if (_isFirebaseReady) {
        await FirebaseAuth.instance.signOut();
      }
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google sign-out issues for email/password users.
      }
      _user = null;
      _isGuest = false;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> syncFavorites(Set<String> favorites) async {
    final user = _user;
    if (!_isFirebaseReady || user == null) return;
    final mapped = <String, bool>{for (final id in favorites) id: true};
    await _usersRef.child(user.uid).child('favorites').set(mapped);
  }

  Future<void> _syncUserProfile(
    User user, {
    required bool createDefaults,
  }) async {
    if (!_isFirebaseReady) return;

    final uidRef = _usersRef.child(user.uid);
    await uidRef.child('profile_info').update({
      'uid': user.uid,
      'email': user.email,
      'display_name': user.displayName,
      'photo_url': user.photoURL,
      'last_login_at': ServerValue.timestamp,
    });

    final subRef = uidRef.child('subscription');
    if (createDefaults) {
      await subRef.update({
        'plan': 'free',
        'active': false,
        'updated_at': ServerValue.timestamp,
      });
      return;
    }

    final subSnap = await subRef.get();
    if (!subSnap.exists) {
      await subRef.set({
        'plan': 'free',
        'active': false,
        'updated_at': ServerValue.timestamp,
      });
    } else {
      await subRef.update({'updated_at': ServerValue.timestamp});
    }
  }
}
