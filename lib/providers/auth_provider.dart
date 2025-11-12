import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = UserModel(
      id: '1',
      username: 'user123',
      displayName: 'User Name',
      bio: 'Flutter Developer | Tech Enthusiast',
      profileImage: 'https://i.pravatar.cc/150?img=1',
      followers: 1234,
      following: 567,
      joinDate: DateTime(2020, 1, 1),
      isVerified: true,
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> register(String email, String password, String username) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = UserModel(
      id: '1',
      username: username,
      displayName: username,
      joinDate: DateTime.now(),
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}