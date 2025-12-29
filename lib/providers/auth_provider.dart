import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart' as app;

/// Real authentication provider (FirebaseAuth + GoogleSignIn).
///
/// - Persists onboarding completion to SharedPreferences.
/// - Keeps [_currentUser] in sync with FirebaseAuth authStateChanges.
///
/// IMPORTANT:
/// You MUST configure Firebase in your Flutter app before this works:
/// - Android: android/app/google-services.json + apply google-services plugin
/// - iOS: ios/Runner/GoogleService-Info.plist
class AuthProvider extends ChangeNotifier {
  static const _prefsOnboardingKey = 'hasCompletedOnboarding';

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _hasCompletedOnboarding = false;
  bool _isInitializing = true;
  app.User? _currentUser;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _auth.currentUser != null;
  app.User? get currentUser => _currentUser;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load onboarding state
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding = prefs.getBool(_prefsOnboardingKey) ?? false;

    // Listen to auth changes
    _auth.authStateChanges().listen((fb.User? user) {
      _currentUser = user == null ? null : _mapFirebaseUserToAppUser(user);
      notifyListeners();
    });

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsOnboardingKey, true);
    notifyListeners();
  }

  /// Google sign-in using FirebaseAuth.
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) {
      // User cancelled
      return;
    }
    final GoogleSignInAuthentication gAuth = await gUser.authentication;

    final credential = fb.GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    await _auth.signInWithCredential(credential);
    await completeOnboarding();
  }

  /// Email/password sign-in using FirebaseAuth.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    await completeOnboarding();
  }

  /// Email/password registration using FirebaseAuth.
  Future<void> registerWithEmail(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null && name.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(name.trim());
      await cred.user!.reload();
    }

    await completeOnboarding();
  }

  Future<void> signOut() async {
    // GoogleSignIn needs explicit signOut too.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
    await _auth.signOut();
    notifyListeners();
  }

  app.User _mapFirebaseUserToAppUser(fb.User user) {
    // Minimal mapping for your current app model.
    // You can later extend this by loading profile fields from Firestore.
    return app.User(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      phone: user.phoneNumber ?? '',
      district: 'Unknown',
      avatar: user.photoURL,
      joinDate: DateTime.now(),
      rating: 0,
      reviewCount: 0,
    );
  }
}
