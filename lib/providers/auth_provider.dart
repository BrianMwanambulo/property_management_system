import 'package:flutter/foundation.dart';
import '../api/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.getCurrentUserData();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = await _authService.signInWithEmailAndPassword(email, password);
      if (uid != null) {
        _user = await _authService.getCurrentUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      if (uid != null) {
        _user = await _authService.getCurrentUserData();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
  }
}