import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart' as app;
import '../services/location_service.dart';

// Authentication state and user profile provider.
class AuthProvider extends ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final LocationService _locationService = LocationService();

  bool _isInitializing = true;
  bool _isUpdatingLocation = false;
  DateTime? _lastLocationCheck;
  String? _detectedDistrict;
  String? _locationError;
  app.User? _currentUser;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  // True while the provider is bootstrapping.
  bool get isInitializing => _isInitializing;
  // True when a user is signed in.
  bool get isAuthenticated => _currentUser != null;
  // True while location lookup is in progress.
  bool get isUpdatingLocation => _isUpdatingLocation;
  // Current signed-in user, if available.
  app.User? get currentUser => _currentUser;
  // Error message from location lookup.
  String? get locationError => _locationError;
  // Current detected or saved district label.
  String get locationDistrict =>
      (_detectedDistrict != null && _detectedDistrict!.isNotEmpty)
          ? _detectedDistrict!
          : (_currentUser?.district ?? 'Unknown');

  // Initializes auth and user listeners.
  AuthProvider() {
    _init();
  }

  // Connects to Firebase auth and user documents.
  Future<void> _init() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null) {
      await _ensureUserDoc(existingUser);
      _bindUserDoc(existingUser);
    }

    // Subscribe to auth changes.
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

  // Updates the user district from device location.
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

  // Signs in with Google.
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
    if (gUser == null) {
      // Stop if the sign-in flow was dismissed.
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

  // Signs in with email and password.
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = _auth.currentUser;
    if (user != null) {
      await _ensureUserDoc(user);
      _bindUserDoc(user);
    }
  }

  // Creates a new account with email and password.
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

  // Signs out of the app and clears local state.
  Future<void> signOut() async {
    // Sign out of Google if it was used.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
    }
    await _auth.signOut();
    _userSub?.cancel();
    _userSub = null;
    _isUpdatingLocation = false;
    _lastLocationCheck = null;
    _detectedDistrict = null;
    notifyListeners();
  }

  // Ensures a user document exists in Firestore.
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
    );

    await docRef.set(newUser.toJson());
  }

  // Subscribes to the current user's Firestore document.
  void _bindUserDoc(fb.User user) {
    _userSub?.cancel();
    _userSub = _db.collection('users').doc(user.uid).snapshots().listen((snap) {
      if (!snap.exists) return;
      _currentUser = app.User.fromFirestore(snap);
      notifyListeners();
    });
  }
}
