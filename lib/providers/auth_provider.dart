import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../data/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  User? get currentUser => _currentUser;

  void completeOnboarding() {
    _hasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> login({bool isGoogle = true}) async {
    // Simulate login delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _isAuthenticated = true;
    _hasCompletedOnboarding = true;
    _currentUser = MockData.currentUser;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }

  void showLoginPrompt() {
    // This method can be used to trigger login dialog
    notifyListeners();
  }
}
