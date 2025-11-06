import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesService {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  // User Data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _preferences?.setString('user_data', json.encode(userData));
  }

  static Future<void> saveAuthDetails(Map<String, String> authDetails) async {
    await _preferences?.setString('auth_data', json.encode(authDetails));
  }

  static bool authenticateUser(String email, String password) {
    final authDetails = _preferences?.getString('auth_data');
    if (authDetails != null) {
      final decodedDetails = jsonDecode(authDetails);
      if (decodedDetails['email'] == email &&
          decodedDetails['password'] == password) {
        return true;
      }
    } else {
      return false;
    }
    return false;
  }

  static Map<String, dynamic>? getUserData() {
    final userDataString = _preferences?.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Properties
  static Future<void> saveProperties(
    List<Map<String, dynamic>> properties,
  ) async {
    await _preferences?.setString('properties', json.encode(properties));
    await _preferences?.setString(
      'properties_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Map<String, dynamic>>? getProperties() {
    final propertiesString = _preferences?.getString('properties');
    if (propertiesString != null) {
      final List<dynamic> decoded = json.decode(propertiesString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  static DateTime? getPropertiesTimestamp() {
    final timestamp = _preferences?.getString('properties_timestamp');
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  // Payments
  static Future<void> savePayments(List<Map<String, dynamic>> payments) async {
    await _preferences?.setString('payments', json.encode(payments));
    await _preferences?.setString(
      'payments_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Map<String, dynamic>>? getPayments() {
    final paymentsString = _preferences?.getString('payments');
    if (paymentsString != null) {
      final List<dynamic> decoded = json.decode(paymentsString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  // Maintenance Requests
  static Future<void> saveMaintenanceRequests(
    List<Map<String, dynamic>> requests,
  ) async {
    await _preferences?.setString(
      'maintenance_requests',
      json.encode(requests),
    );
    await _preferences?.setString(
      'maintenance_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Map<String, dynamic>>? getMaintenanceRequests() {
    final requestsString = _preferences?.getString('maintenance_requests');
    if (requestsString != null) {
      final List<dynamic> decoded = json.decode(requestsString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  // Dashboard Stats
  static Future<void> saveDashboardStats(Map<String, dynamic> stats) async {
    await _preferences?.setString('dashboard_stats', json.encode(stats));
    await _preferences?.setString(
      'stats_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  static Map<String, dynamic>? getDashboardStats() {
    final statsString = _preferences?.getString('dashboard_stats');
    if (statsString != null) {
      return json.decode(statsString) as Map<String, dynamic>;
    }
    return null;
  }

  // Recent Activities
  static Future<void> saveRecentActivities(
    List<Map<String, dynamic>> activities,
  ) async {
    await _preferences?.setString('recent_activities', json.encode(activities));
    await _preferences?.setString(
      'activities_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  static List<Map<String, dynamic>>? getRecentActivities() {
    final activitiesString = _preferences?.getString('recent_activities');
    if (activitiesString != null) {
      final List<dynamic> decoded = json.decode(activitiesString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  // Pending Sync Queue
  static Future<void> addPendingSync(Map<String, dynamic> operation) async {
    final pending = getPendingSyncs() ?? [];
    pending.add(operation);
    await _preferences?.setString('pending_syncs', json.encode(pending));
  }

  static List<Map<String, dynamic>>? getPendingSyncs() {
    final syncsString = _preferences?.getString('pending_syncs');
    if (syncsString != null) {
      final List<dynamic> decoded = json.decode(syncsString);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    }
    return null;
  }

  static Future<void> clearPendingSyncs() async {
    await _preferences?.remove('pending_syncs');
  }

  static Future<void> removePendingSync(int index) async {
    final pending = getPendingSyncs() ?? [];
    if (index >= 0 && index < pending.length) {
      pending.removeAt(index);
      await _preferences?.setString('pending_syncs', json.encode(pending));
    }
  }

  // Network Status
  static Future<void> setLastSyncTime(DateTime time) async {
    await _preferences?.setString('last_sync_time', time.toIso8601String());
  }

  static DateTime? getLastSyncTime() {
    final timeString = _preferences?.getString('last_sync_time');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await _preferences?.clear();
  }

  // Clear specific data
  static Future<void> clearUserData() async {
    await _preferences?.remove('user_data');
  }

  // Check if data is stale (older than specified duration)
  static bool isDataStale(String key, Duration maxAge) {
    final timestamp = _preferences?.getString('${key}_timestamp');
    if (timestamp == null) return true;

    final dataTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(dataTime) > maxAge;
  }
}
