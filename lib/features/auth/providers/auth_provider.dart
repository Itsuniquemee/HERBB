import 'package:flutter/material.dart';
import '../../../core/models/user.dart';
import '../../../core/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get userRole => _currentUser?.role;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = StorageService.getUserData('currentUser');
    if (userData != null) {
      _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, UserRole role) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // For demo purposes - accept any credentials
      _currentUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: email.split('@')[0],
        email: email,
        phone: '+91 9876543210',
        role: role,
        createdAt: DateTime.now(),
      );

      _isAuthenticated = true;

      // Save to storage
      await StorageService.saveUserData('currentUser', _currentUser!.toJson());
      await StorageService.saveUserData(
          'authToken', 'demo_token_${_currentUser!.id}');

      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _isAuthenticated = false;

    await StorageService.saveUserData('currentUser', null);
    await StorageService.saveUserData('authToken', null);

    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    // Create updated user
    final updatedUser = User(
      id: _currentUser!.id,
      name: updates['name'] ?? _currentUser!.name,
      email: updates['email'] ?? _currentUser!.email,
      phone: updates['phone'] ?? _currentUser!.phone,
      role: _currentUser!.role,
      profileImage: updates['profileImage'] ?? _currentUser!.profileImage,
      createdAt: _currentUser!.createdAt,
      metadata: updates['metadata'] ?? _currentUser!.metadata,
    );

    _currentUser = updatedUser;
    await StorageService.saveUserData('currentUser', _currentUser!.toJson());

    notifyListeners();
  }
}
