import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart' as app;
import '../services/location_service.dart';

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
  static const _prefsOnboardingVersionKey = 'onboardingVersion';
  static const _onboardingVersion = 1;

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocationService _locationService = LocationService();

  bool _hasCompletedOnboarding = false;
  bool _isInitializing = true;
  bool _isUpdatingLocation = false;
  DateTime? _lastLocationCheck;
  String? _detectedDistrict;
  String? _locationError;
  app.User? _currentUser;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitializing => _isInitializing;
  bool get isAuthenticated => _currentUser != null;
  bool get isUpdatingLocation => _isUpdatingLocation;
  app.User? get currentUser => _currentUser;
  String? get locationError => _locationError;
  String get locationDistrict =>
      (_detectedDistrict != null && _detectedDistrict!.isNotEmpty)
          ? _detectedDistrict!
          : (_currentUser?.district ?? 'Unknown');

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Load onboarding state
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_prefsOnboardingVersionKey);
    final isCurrentVersion = storedVersion == _onboardingVersion;
    _hasCompletedOnboarding =
        (prefs.getBool(_prefsOnboardingKey) ?? false) && isCurrentVersion;

    final existingUser = _auth.currentUser;
    if (existingUser != null) {
      await _ensureUserDoc(existingUser);
      _bindUserDoc(existingUser);
    }

    // Listen to auth changes
    _auth.authStateChanges().listen((fb.User? user) async {
      if (user == null) {
        _userSub?.cancel();
        _userSub = null;
        _currentUser = null;
        notifyListeners();
        return;
      }

      await _ensureUserDoc(user);
      _bindUserDoc(user);
    });

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> updateLocationDistrict({bool force = false}) async {
    if (_isUpdatingLocation) return;
    if (!force && _lastLocationCheck != null) {
      final elapsed = DateTime.now().difference(_lastLocationCheck!);
      if (elapsed.inMinutes < 5) return;
    }
    _isUpdatingLocation = true;
    _locationError = null;
    notifyListeners();
    final user = _currentUser;
    try {
      final district = await _locationService.getCurrentDistrict();
      if (district.isEmpty) return;
      _detectedDistrict = district;
      _lastLocationCheck = DateTime.now();
      if (user != null && district != user.district) {
        _currentUser = app.User(
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          district: district,
          avatar: user.avatar,
          joinDate: user.joinDate,
          rating: user.rating,
          reviewCount: user.reviewCount,
        );
      }
      notifyListeners();
      if (user != null && district != user.district) {
        await _db.collection('users').doc(user.id).set(
          {'district': district},
          SetOptions(merge: true),
        );
      }
    } catch (error) {
      _locationError = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Unable to detect location.';
    } finally {
      _isUpdatingLocation = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsOnboardingKey, true);
    await prefs.setInt(_prefsOnboardingVersionKey, _onboardingVersion);
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
    final user = _auth.currentUser;
    if (user != null) {
      await _ensureUserDoc(user);
      _bindUserDoc(user);
    }
  }

  /// Email/password sign-in using FirebaseAuth.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = _auth.currentUser;
    if (user != null) {
      await _ensureUserDoc(user);
      _bindUserDoc(user);
    }
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

    final user = _auth.currentUser;
    if (user != null) {
      await _ensureUserDoc(user);
      _bindUserDoc(user);
    }
  }

  Future<void> signOut() async {
    // GoogleSignIn needs explicit signOut too.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
    await _auth.signOut();
    _userSub?.cancel();
    _userSub = null;
    _isUpdatingLocation = false;
    _lastLocationCheck = null;
    _detectedDistrict = null;
    notifyListeners();
  }

  Future<void> _ensureUserDoc(fb.User user) async {
    final docRef = _db.collection('users').doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) return;

    final newUser = app.User(
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

    await docRef.set(newUser.toJson());
  }

  void _bindUserDoc(fb.User user) {
    _userSub?.cancel();
    _userSub = _db.collection('users').doc(user.uid).snapshots().listen((snap) {
      if (!snap.exists) return;
      _currentUser = app.User.fromFirestore(snap);
      notifyListeners();
    });
  }
}
