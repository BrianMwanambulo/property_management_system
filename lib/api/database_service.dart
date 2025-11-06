import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:property_management_system/models/activity_model.dart';
import 'package:property_management_system/models/user_model.dart';
import '../models/property_model.dart';
import '../models/payment_model.dart';
import '../models/maintenance_model.dart';
import 'local_storage.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Properties
  Stream<List<PropertyModel>> getPropertiesByOwner(
    String ownerUid, {
    String? role,
  }) {
    return _firestore
        .collection('properties')
        .where(role ?? 'ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading properties: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final properties = snapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final propertiesJson = properties
              .map((p) => _propertyToJson(p))
              .toList();
          SharedPreferencesService.saveProperties(propertiesJson);

          return properties;
        });
  }

  Future<List<UserModel>> getAllTenants() async {
    try {
      final response = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'tenant')
          .get();
      return response.docs
          .map((e) => UserModel.fromFirestore(e.data(), e.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading tenants: $e');
      return [];
    }
  }

  Stream<List<PropertyModel>> getAllProperties() {
    return _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading all properties: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final properties = snapshot.docs
              .map((doc) => PropertyModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final propertiesJson = properties
              .map((p) => _propertyToJson(p))
              .toList();
          SharedPreferencesService.saveProperties(propertiesJson);

          return properties;
        });
  }

  Future<List<PropertyModel>> getAllPropertiesFuture() async {
    try {
      final data = await _firestore
          .collection('properties')
          .orderBy('createdAt', descending: true)
          .get();

      final properties = data.docs
          .map((snapshot) => PropertyModel.fromFirestore(snapshot))
          .toList();

      // Save to local storage
      final propertiesJson = properties.map((p) => _propertyToJson(p)).toList();
      await SharedPreferencesService.saveProperties(propertiesJson);

      return properties;
    } catch (e) {
      debugPrint('Error loading properties, using offline data: $e');
      // Return offline data if available
      return _getPropertiesFromCache();
    }
  }

  // Helper method to convert property to JSON
  Map<String, dynamic> _propertyToJson(PropertyModel p) {
    return {
      'id': p.id,
      'name': p.name,
      'ownerUid': p.ownerUid,
      'ownerName': p.ownerName,
      'tenantId': p.tenantId,
      'address': p.address,
      'type': p.type,
      'monthlyRent': p.monthlyRent,
      'isOccupied': p.isOccupied,
      'images': p.images,
      'createdAt': p.createdAt.toIso8601String(),
      'lastUpdated': p.lastUpdated.toIso8601String(),
    };
  }

  // Helper method to get properties from cache
  List<PropertyModel> _getPropertiesFromCache() {
    final offlineData = SharedPreferencesService.getProperties();
    if (offlineData != null) {
      return offlineData.map((data) {
        return PropertyModel(
          id: data['id'] ?? '',
          name: data['name'] ?? '',
          ownerUid: data['ownerUid'] ?? '',
          ownerName: data['ownerName'] ?? '',
          tenantId: data['tenantId'],
          address: data['address'] ?? '',
          type: data['type'] ?? '',
          monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
          isOccupied: data['isOccupied'] ?? false,
          images: List<String>.from(data['images'] ?? []),
          createdAt: DateTime.parse(data['createdAt']),
          lastUpdated: DateTime.parse(data['lastUpdated']),
        );
      }).toList();
    }
    return [];
  }

  Future<void> addProperty(PropertyModel property) async {
    try {
      await _firestore.collection('properties').add(property.toFirestore());
    } catch (e) {
      debugPrint('Error adding property, queuing for sync: $e');
      throw 'Offline - changes will sync when online';
    }
  }

  Future<void> updateProperty(
    String propertyId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('properties').doc(propertyId).update({
        ...data,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('Error updating property: $e');
      throw 'Offline - changes will sync when online';
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _firestore.collection('properties').doc(propertyId).delete();
    } catch (e) {
      debugPrint('Error deleting property: $e');
      throw 'Offline - changes will sync when online';
    }
  }

  // Payments
  Stream<List<PaymentModel>> getPaymentsByProperty(String propertyId) {
    return _firestore
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading payments: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => PaymentModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final paymentsJson = payments.map((p) => _paymentToJson(p)).toList();
          SharedPreferencesService.savePayments(paymentsJson);

          return payments;
        });
  }

  Stream<List<PaymentModel>> getPaymentsByUser(String userUid, {String? role}) {
    return _firestore
        .collection('payments')
        .where(role ?? 'payerUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading payments: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final payments = snapshot.docs
              .map((doc) => PaymentModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final paymentsJson = payments.map((p) => _paymentToJson(p)).toList();
          SharedPreferencesService.savePayments(paymentsJson);

          return payments;
        });
  }

  Future<List<PaymentModel>> getPaymentsByUserFuture(
    String userUid, {
    final isOwner = false,
  }) async {
    try {
      final data = await _firestore
          .collection('payments')
          .where(isOwner ? 'propertyOwnerId' : 'payerUid', isEqualTo: userUid)
          .orderBy('createdAt', descending: true)
          .get();
      final payments = data.docs
          .map((doc) => PaymentModel.fromFirestore(doc))
          .toList();

      // Save to local storage
      final paymentsJson = payments.map((p) => _paymentToJson(p)).toList();
      await SharedPreferencesService.savePayments(paymentsJson);

      return payments;
    } catch (e) {
      debugPrint('Error loading payments, using offline data: $e');
      // Return offline data if available
      return _getPaymentsFromCache();
    }
  }

  // Helper method to convert payment to JSON
  Map<String, dynamic> _paymentToJson(PaymentModel p) {
    return {
      'id': p.id,
      'propertyId': p.propertyId,
      'propertyOwnerId': p.propertyOwnerId,
      'propertyName': p.propertyName,
      'payerUid': p.payerUid,
      'payerName': p.payerName,
      'amount': p.amount,
      'description': p.description,
      'status': p.status,
      'createdAt': p.createdAt.toIso8601String(),
      'paidDate': p.paidDate.toIso8601String(),
    };
  }

  // Helper method to get payments from cache
  List<PaymentModel> _getPaymentsFromCache() {
    final offlineData = SharedPreferencesService.getPayments();
    if (offlineData != null) {
      return offlineData.map((data) {
        return PaymentModel(
          id: data['id'] ?? '',
          propertyId: data['propertyId'] ?? '',
          propertyOwnerId: data['propertyOwnerId'] ?? '',
          propertyName: data['propertyName'] ?? '',
          payerUid: data['payerUid'] ?? '',
          payerName: data['payerName'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          description: data['description'] ?? '',
          status: data['status'] ?? 'pending',
          createdAt: DateTime.parse(data['createdAt']),
          paidDate: DateTime.parse(data['paidDate']),
        );
      }).toList();
    }
    return [];
  }

  Future<void> addPayment(PaymentModel payment) async {
    try {
      await _firestore.collection('payments').add(payment.toFirestore());
    } catch (e) {
      debugPrint('Error adding payment: $e');
      throw 'Offline - payment will sync when online';
    }
  }

  Future<void> updatePaymentStatus(
    String paymentId,
    String status, {
    DateTime? paidDate,
  }) async {
    try {
      final data = {
        'status': status,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      if (paidDate != null) {
        data['paidDate'] = Timestamp.fromDate(paidDate);
      }

      await _firestore.collection('payments').doc(paymentId).update(data);
    } catch (e) {
      debugPrint('Error updating payment: $e');
      throw 'Offline - changes will sync when online';
    }
  }

  // Maintenance Requests
  Stream<List<MaintenanceModel>> getMaintenanceByProperty(String propertyId) {
    return _firestore
        .collection('maintenance_requests')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading maintenance: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => MaintenanceModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final requestsJson = requests
              .map((r) => _maintenanceToJson(r))
              .toList();
          SharedPreferencesService.saveMaintenanceRequests(requestsJson);

          return requests;
        });
  }

  Stream<List<MaintenanceModel>> getMaintenanceByUser(
    String userUid, {
    String? role,
  }) {
    return _firestore
        .collection('maintenance_requests')
        .where(role ?? 'requesterUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error loading maintenance: $error');
          return const Stream.empty();
        })
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => MaintenanceModel.fromFirestore(doc))
              .toList();

          // Save to local storage
          final requestsJson = requests
              .map((r) => _maintenanceToJson(r))
              .toList();
          SharedPreferencesService.saveMaintenanceRequests(requestsJson);

          return requests;
        });
  }

  Future<List<MaintenanceModel>> getMaintenanceByUserFuture(
    String userUid, {
    bool isOwner = false,
  }) async {
    try {
      final data = await _firestore
          .collection('maintenance_requests')
          .where(
            isOwner ? 'propertyOwnerId' : 'requesterUid',
            isEqualTo: userUid,
          )
          .orderBy('createdAt', descending: true)
          .get();

      final requests = data.docs
          .map((doc) => MaintenanceModel.fromFirestore(doc))
          .toList();

      final requestsJson = requests.map((r) => _maintenanceToJson(r)).toList();
      await SharedPreferencesService.saveMaintenanceRequests(requestsJson);

      return requests;
    } catch (e) {
      debugPrint('Error loading maintenance, using offline data: $e');
      // Return offline data if available
      return _getMaintenanceFromCache();
    }
  }

  // Helper method to convert maintenance to JSON
  Map<String, dynamic> _maintenanceToJson(MaintenanceModel m) {
    return {
      'id': m.id,
      'propertyId': m.propertyId,
      'propertyOwnerId': m.propertyOwnerId,
      'propertyNumber': m.propertyNumber,
      'requesterUid': m.requesterUid,
      'requesterName': m.requesterName,
      'title': m.title,
      'description': m.description,
      'category': m.category,
      'priority': m.priority,
      'status': m.status,
      'images': m.images,
      'assignedTo': m.assignedTo,
      'createdAt': m.createdAt.toIso8601String(),
      'completedAt': m.completedAt?.toIso8601String(),
    };
  }

  // Helper method to get maintenance from cache
  List<MaintenanceModel> _getMaintenanceFromCache() {
    final offlineData = SharedPreferencesService.getMaintenanceRequests();
    if (offlineData != null) {
      return offlineData.map((data) {
        return MaintenanceModel(
          id: data['id'] ?? '',
          propertyId: data['propertyId'] ?? '',
          propertyOwnerId: data['propertyOwnerId'] ?? '',
          propertyNumber: data['propertyNumber'] ?? '',
          requesterUid: data['requesterUid'] ?? '',
          requesterName: data['requesterName'] ?? '',
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          category: data['category'] ?? 'other',
          priority: data['priority'] ?? 'medium',
          status: data['status'] ?? 'pending',
          images: List<String>.from(data['images'] ?? []),
          assignedTo: data['assignedTo'],
          createdAt: DateTime.parse(data['createdAt']),
          completedAt: data['completedAt'] != null
              ? DateTime.parse(data['completedAt'])
              : null,
        );
      }).toList();
    }
    return [];
  }

  Future<void> addMaintenanceRequest(MaintenanceModel maintenance) async {
    try {
      await _firestore
          .collection('maintenance_requests')
          .add(maintenance.toFirestore());
    } catch (e) {
      debugPrint('Error adding maintenance request: $e');
      throw 'Offline - request will sync when online';
    }
  }

  Future<void> updateMaintenanceStatus(
    String maintenanceId,
    String status, {
    String? assignedTo,
  }) async {
    try {
      final data = {
        'status': status,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      };

      if (assignedTo != null) {
        data['assignedTo'] = assignedTo;
      }

      if (status == 'completed') {
        data['completedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _firestore
          .collection('maintenance_requests')
          .doc(maintenanceId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating maintenance: $e');
      throw 'Offline - changes will sync when online';
    }
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardStats(
    String? userUid, {
    bool isAdmin = false,
  }) async {
    try {
      final stats = <String, dynamic>{};

      if (userUid != null) {
        final propertiesQuery = await _firestore
            .collection('properties')
            .where('ownerUid', isEqualTo: userUid)
            .get();
        stats['totalProperties'] = propertiesQuery.docs.length;

        final paymentsQuery = await _firestore
            .collection('payments')
            .where(isAdmin ? 'propertyOwnerId' : 'payerUid', isEqualTo: userUid)
            .get();
        int pendingPayments = 0;
        for (var property in propertiesQuery.docs) {
          for (var payment in paymentsQuery.docs) {
            if (payment['propertyId'] != property.id) {
              pendingPayments++;
            }
          }
        }
        stats['pendingPayments'] = pendingPayments;

        double amount = 0;
        for (var val in paymentsQuery.docs) {
          amount += val['amount'];
        }
        stats['monthlyRevenue'] = amount;
        final maintenanceQuery = await _firestore
            .collection('maintenance_requests')
            .where(
              isAdmin ? 'propertyOwnerId' : 'requesterUid',
              isEqualTo: userUid,
            )
            .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
            .get();
        stats['activeMaintenanceRequests'] = maintenanceQuery.docs.length;
      } else {
        final propertiesQuery = await _firestore.collection('properties').get();
        stats['totalProperties'] = propertiesQuery.docs.length;

        final paymentsQuery = await _firestore
            .collection('payments')
            .where('status', isEqualTo: 'pending')
            .get();
        stats['pendingPayments'] = paymentsQuery.docs.length;

        final maintenanceQuery = await _firestore
            .collection('maintenance_requests')
            .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
            .get();
        stats['activeMaintenanceRequests'] = maintenanceQuery.docs.length;
      }

      // Save to local storage
      await SharedPreferencesService.saveDashboardStats(stats);

      return stats;
    } catch (e) {
      debugPrint('Error loading dashboard stats, using offline data: $e');
      // Return offline data if available
      return SharedPreferencesService.getDashboardStats() ?? {};
    }
  }

  Future<double> getMonthlyRevenue(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 1);

      final paymentsQuery = await _firestore
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .where(
            'paidDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('paidDate', isLessThan: Timestamp.fromDate(endDate))
          .get();

      double totalRevenue = 0;
      for (final doc in paymentsQuery.docs) {
        final payment = PaymentModel.fromFirestore(doc);
        totalRevenue += payment.amount;
      }

      return totalRevenue;
    } catch (e) {
      debugPrint('Error calculating revenue: $e');
      return 0.0;
    }
  }

  Future<List<ActivityModel>> getOwnerRecentActivities(String ownerUid) async {
    try {
      final activities = <ActivityModel>[];

      final ownerProperties = await _firestore
          .collection('properties')
          .where('ownerUid', isEqualTo: ownerUid)
          .get();
      final propertyIds = ownerProperties.docs.map((e) => e.id).toList();

      if (propertyIds.isNotEmpty) {
        final payments = await _firestore
            .collection('payments')
            .where('propertyId', whereIn: propertyIds)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        for (final doc in payments.docs) {
          final payment = PaymentModel.fromFirestore(doc);
          activities.add(
            ActivityModel(
              id: payment.id,
              type: 'payment',
              title: 'Payment Received',
              subtitle:
                  '${payment.propertyName} - K ${payment.amount.toStringAsFixed(2)}',
              createdAt: payment.createdAt,
              icon: Icons.payment,
              color: Colors.green,
            ),
          );
        }
      }

      if (propertyIds.isNotEmpty) {
        final maintenance = await _firestore
            .collection('maintenance_requests')
            .where('propertyId', whereIn: propertyIds)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        for (final doc in maintenance.docs) {
          final request = MaintenanceModel.fromFirestore(doc);
          activities.add(
            ActivityModel(
              id: request.id,
              type: 'maintenance',
              title: 'Maintenance Request',
              subtitle: '${request.title} (${request.status})',
              createdAt: request.createdAt,
              icon: Icons.build,
              color: Colors.blue,
            ),
          );
        }
      }

      for (final doc in ownerProperties.docs.take(5)) {
        final property = PropertyModel.fromFirestore(doc);
        activities.add(
          ActivityModel(
            id: property.id,
            type: 'property',
            title: 'New Property Registered',
            subtitle: property.name,
            createdAt: property.createdAt,
            icon: Icons.business,
            color: Colors.purple,
          ),
        );
      }

      activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Save to local storage
      final activitiesJson = activities
          .take(10)
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

      return activities.take(10).toList();
    } catch (e) {
      debugPrint('Error loading activities, using offline data: $e');
      // Return offline data if available
      return _getActivitiesFromCache();
    }
  }

  // Helper method to get activities from cache
  List<ActivityModel> _getActivitiesFromCache() {
    final offlineData = SharedPreferencesService.getRecentActivities();
    if (offlineData != null) {
      return offlineData.map((data) {
        return ActivityModel(
          id: data['id'] ?? '',
          type: data['type'] ?? '',
          title: data['title'] ?? '',
          subtitle: data['subtitle'] ?? '',
          createdAt: DateTime.parse(data['createdAt']),
          icon: Icons.info,
          color: Colors.grey,
        );
      }).toList();
    }
    return [];
  }
}
