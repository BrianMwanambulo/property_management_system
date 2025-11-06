import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'database_service.dart';
import 'local_storage.dart';
import '../models/property_model.dart';
import '../models/payment_model.dart';
import '../models/maintenance_model.dart';

class SyncService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Connectivity _connectivity = Connectivity();

  bool _isSyncing = false;
  bool _isOnline = true;
  DateTime? _lastSyncTime;
  StreamSubscription? _connectivitySubscription;

  bool get isSyncing => _isSyncing;

  bool get isOnline => _isOnline;

  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService() {
    _initConnectivityListener();
    _lastSyncTime = SharedPreferencesService.getLastSyncTime();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      final wasOffline = !_isOnline;
      _isOnline = result.first != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        debugPrint('🌐 Back online - syncing pending operations');
        syncPendingOperations();
      }

      notifyListeners();
    });
  }

  // Check current connectivity status
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.first != ConnectivityResult.none;
    notifyListeners();
    return _isOnline;
  }

  // Sync all data from server to local storage
  Future<void> syncFromServer(String userUid, {String? role}) async {
    if (!_isOnline) {
      debugPrint('📴 Offline - skipping sync from server');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('📥 Syncing data from server...');

      // Sync Properties
      final properties = role == 'admin'
          ? await _databaseService.getAllPropertiesFuture()
          : await _databaseService.getPropertiesByOwner(userUid).first;

      final propertiesJson = properties.map((p) => p.toFirestore()).toList();
      await SharedPreferencesService.saveProperties(propertiesJson);
      debugPrint('✅ Properties synced: ${properties.length}');

      // Sync Payments
      final payments = await _databaseService.getPaymentsByUserFuture(userUid);
      final paymentsJson = payments.map((p) => p.toFirestore()).toList();
      await SharedPreferencesService.savePayments(paymentsJson);
      debugPrint('✅ Payments synced: ${payments.length}');

      // Sync Maintenance Requests
      final maintenance = await _databaseService.getMaintenanceByUserFuture(
        userUid,
      );
      final maintenanceJson = maintenance.map((m) => m.toFirestore()).toList();
      await SharedPreferencesService.saveMaintenanceRequests(maintenanceJson);
      debugPrint('✅ Maintenance requests synced: ${maintenance.length}');

      // Sync Dashboard Stats
      final stats = await _databaseService.getDashboardStats(userUid);
      await SharedPreferencesService.saveDashboardStats(stats);
      debugPrint('✅ Dashboard stats synced');

      // Sync Recent Activities (for property owners)
      if (role == 'property_owner' || role == 'admin') {
        final activities = await _databaseService.getOwnerRecentActivities(
          userUid,
        );
        final activitiesJson = activities
            .map(
              (a) => {
                'id': a.id,
                'type': a.type,
                'title': a.title,
                'subtitle': a.subtitle,
                'createdAt': a.createdAt.toIso8601String(),
              },
            )
            .toList();
        await SharedPreferencesService.saveRecentActivities(activitiesJson);
        debugPrint('✅ Recent activities synced: ${activities.length}');
      }

      _lastSyncTime = DateTime.now();
      await SharedPreferencesService.setLastSyncTime(_lastSyncTime!);
      debugPrint('✅ Sync completed successfully');
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('❌ Sync error: $e');
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Add operation to pending sync queue
  Future<void> queueOperation({
    required String type,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final pendingOperation = {
      'type': type, // 'property', 'payment', 'maintenance'
      'operation': operation, // 'add', 'update', 'delete'
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    };

    await SharedPreferencesService.addPendingSync(pendingOperation);
    debugPrint('📝 Queued operation: $type - $operation');

    // Try to sync immediately if online
    if (_isOnline) {
      await syncPendingOperations();
    }
  }

  // Sync pending operations to server
  Future<void> syncPendingOperations() async {
    if (!_isOnline) {
      debugPrint('📴 Offline - cannot sync pending operations');
      return;
    }

    final pendingOps = SharedPreferencesService.getPendingSyncs();
    if (pendingOps == null || pendingOps.isEmpty) {
      debugPrint('✅ No pending operations to sync');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    debugPrint('🔄 Syncing ${pendingOps.length} pending operations...');
    final List<int> successfulIndices = [];

    for (int i = 0; i < pendingOps.length; i++) {
      final op = pendingOps[i];
      try {
        await _executePendingOperation(op);
        successfulIndices.add(i);
        debugPrint('✅ Synced operation ${i + 1}/${pendingOps.length}');
      } catch (e) {
        debugPrint('❌ Failed to sync operation ${i + 1}: $e');
        // Increment retry count
        op['retryCount'] = (op['retryCount'] ?? 0) + 1;

        // Remove if retry count exceeds limit
        if (op['retryCount'] > 5) {
          debugPrint('⚠️ Operation exceeded retry limit, removing...');
          successfulIndices.add(i);
        }
      }
    }

    // Remove successful operations
    for (int i = successfulIndices.length - 1; i >= 0; i--) {
      await SharedPreferencesService.removePendingSync(successfulIndices[i]);
    }

    _isSyncing = false;
    notifyListeners();
    debugPrint('✅ Pending operations sync completed');
  }

  Future<void> _executePendingOperation(Map<String, dynamic> op) async {
    final type = op['type'];
    final operation = op['operation'];
    final data = op['data'];

    switch (type) {
      case 'property':
        await _syncPropertyOperation(operation, data);
        break;
      case 'payment':
        await _syncPaymentOperation(operation, data);
        break;
      case 'maintenance':
        await _syncMaintenanceOperation(operation, data);
        break;
      default:
        debugPrint('⚠️ Unknown operation type: $type');
    }
  }

  Future<void> _syncPropertyOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'add':
        final property = PropertyModel.fromFirestore(
          _createMockDoc(data['id'], data),
        );
        await _databaseService.addProperty(property);
        break;
      case 'update':
        await _databaseService.updateProperty(data['id'], data);
        break;
      case 'delete':
        await _databaseService.deleteProperty(data['id']);
        break;
    }
  }

  Future<void> _syncPaymentOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'add':
        final payment = PaymentModel.fromFirestore(
          _createMockDoc(data['id'], data),
        );
        await _databaseService.addPayment(payment);
        break;
      case 'update':
        await _databaseService.updatePaymentStatus(
          data['id'],
          data['status'],
          paidDate: data['paidDate'] != null
              ? DateTime.parse(data['paidDate'])
              : null,
        );
        break;
    }
  }

  Future<void> _syncMaintenanceOperation(
    String operation,
    Map<String, dynamic> data,
  ) async {
    switch (operation) {
      case 'add':
        final maintenance = MaintenanceModel.fromFirestore(
          _createMockDoc(data['id'], data),
        );
        await _databaseService.addMaintenanceRequest(maintenance);
        break;
      case 'update':
        await _databaseService.updateMaintenanceStatus(
          data['id'],
          data['status'],
          assignedTo: data['assignedTo'],
        );
        break;
    }
  }

  // Helper to create mock DocumentSnapshot for fromFirestore
  dynamic _createMockDoc(String id, Map<String, dynamic> data) {
    return _MockDocumentSnapshot(id, data);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

// Mock DocumentSnapshot for offline data
class _MockDocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  _MockDocumentSnapshot(this._id, this._data);

  String get id => _id;

  Map<String, dynamic>? data() => _data;
}
