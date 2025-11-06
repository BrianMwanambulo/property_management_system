import 'package:flutter/foundation.dart';
import 'package:property_management_system/api/local_storage.dart';
import 'package:property_management_system/api/sync_service.dart';
import '../api/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  bool _isOffline = false;
  SyncService? _syncService;

  UserModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isLoggedIn => _user != null;

  bool get isOffline => _isOffline;

  void setSyncService(SyncService syncService) {
    _syncService = syncService;
  }

  set user(UserModel userModel) {
    _user = userModel;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Initialize Shared Preferences
      await SharedPreferencesService.init();

      // Try to get user from online first
      _user = await _authService.getCurrentUserData();

      if (_user != null) {
        // Save user data for offline use
        await SharedPreferencesService.saveUserData(_user!.toFirestore());
        _isOffline = false;

        // Trigger initial sync if sync service is available
        if (_syncService != null) {
          _syncService!
              .syncFromServer(_user!.uid, role: _user!.role)
              .catchError((e) {
                debugPrint('Initial sync error: $e');
              });
        }
      } else {
        // Try to load user from offline storage
        await _loadUserFromOffline();
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      // Load user from offline storage if online fails
      await _loadUserFromOffline();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserFromOffline() async {
    final userData = SharedPreferencesService.getUserData();
    if (userData != null) {
      _user = UserModel.fromFirestore(userData, userData['uid'] ?? '');
      _isOffline = true;
      debugPrint('📴 Loaded user from offline storage');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      if (uid != null) {
        _user = await _authService.getCurrentUserData();

        // Save user data for offline use
        if (_user != null) {
          await SharedPreferencesService.saveUserData(_user!.toFirestore());

          // Sync data after successful login
          if (_syncService != null) {
            _syncService!
                .syncFromServer(_user!.uid, role: _user!.role)
                .catchError((e) {
                  debugPrint('Post-login sync error: $e');
                });
          }
        }

        _isOffline = false;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e, stackTrace) {
      _isLoading = false;
      debugPrintStack(stackTrace: stackTrace);
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
    String role = 'property_owner',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );
      if (uid != null) {
        _user = await _authService.getCurrentUserData();

        // Save user data for offline use
        if (_user != null) {
          await SharedPreferencesService.saveUserData(_user!.toFirestore());

          // Sync data after successful signup
          if (_syncService != null) {
            _syncService!
                .syncFromServer(_user!.uid, role: _user!.role)
                .catchError((e) {
                  debugPrint('Post-signup sync error: $e');
                });
          }
        }

        _isOffline = false;
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
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }

    // Clear local data
    await SharedPreferencesService.clearAllData();
    _user = null;
    _isOffline = false;
    notifyListeners();
  }

  // Refresh user data from server
  Future<void> refreshUserData() async {
    if (_user == null) return;

    try {
      final updatedUser = await _authService.getCurrentUserData();
      if (updatedUser != null) {
        _user = updatedUser;
        await SharedPreferencesService.saveUserData(_user!.toFirestore());
        _isOffline = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
      _isOffline = true;
      notifyListeners();
    }
  }

  // Check if we need to sync
  bool needsSync() {
    final lastSync = SharedPreferencesService.getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    // Sync if last sync was more than 5 minutes ago
    return difference.inMinutes > 5;
  }
}
