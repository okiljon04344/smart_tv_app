import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  static const String tvAdminBlockedMessage =
      'Admin account TV qurilmada login qila olmaydi';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  User? _user;
  bool _hasAdminClaim = false;
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

  /// Admin rights come from the `admin` custom claim, which only the Admin
  /// SDK can set (see tools/set_admin_claim). `database.rules.json` checks the
  /// same claim, so the client flag only decides what UI is shown.
  Future<bool> _readAdminClaim(User user) async {
    try {
      final token = await user.getIdTokenResult(true);
      return token.claims?['admin'] == true;
    } catch (e) {
      debugPrint('Failed to read admin claim: $e');
      return false;
    }
  }

  Future<void> _signOutEverywhere() async {
    if (_isFirebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out issues for email/password users.
    }
  }

  /// Applies a freshly signed-in [user]. Admin accounts are not allowed on TV
  /// devices, so they are signed out again there.
  Future<void> _applySignedInUser(
    User? user, {
    required bool createDefaults,
  }) async {
    _user = user;
    _hasAdminClaim = user != null && await _readAdminClaim(user);
    if (user != null && _hasAdminClaim && _isTvLikeDevice) {
      await _signOutEverywhere();
      _user = null;
      _hasAdminClaim = false;
      _error = tvAdminBlockedMessage;
      return;
    }
    if (user != null) {
      await _syncUserProfile(user, createDefaults: createDefaults);
    }
    _error = null;
  }

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _user != null || _isGuest;
  bool get isAdmin => _hasAdminClaim;
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
      await _applySignedInUser(
        _isFirebaseReady ? FirebaseAuth.instance.currentUser : null,
        createDefaults: false,
      );
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
      final auth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      await _applySignedInUser(userCredential.user, createDefaults: false);
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

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      await _applySignedInUser(userCredential.user, createDefaults: false);
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
      await _applySignedInUser(userCredential.user, createDefaults: true);
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
      await _signOutEverywhere();
      _user = null;
      _hasAdminClaim = false;
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
