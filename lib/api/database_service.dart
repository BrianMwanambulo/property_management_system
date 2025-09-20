import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:property_management_system/models/activity_model.dart';
import 'package:property_management_system/models/user_model.dart';
import '../models/property_model.dart';
import '../models/payment_model.dart';
import '../models/maintenance_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Properties
  Stream<List<PropertyModel>> getPropertiesByOwner(String ownerUid,{String? role}) {
    return _firestore
        .collection('properties')
        .where(role??  'ownerUid', isEqualTo: ownerUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PropertyModel.fromFirestore(doc))
        .toList());
  }

  Future<List<UserModel>> getAllTenants()async{
    final response = await _firestore.collection('users').where('role',isEqualTo: 'tenant').get();
    return response.docs.map((e) => UserModel.fromFirestore(e.data(), e.id),).toList();
  }

  Stream<List<PropertyModel>> getAllProperties() {
    return _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PropertyModel.fromFirestore(doc))
        .toList());
  }

  Future<List<PropertyModel>> getAllPropertiesFuture() async {
    final data  = await _firestore
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .get();
    return data.docs.map((snapshot) => PropertyModel.fromFirestore(snapshot))
        .toList();
  }

  Future<void> addProperty(PropertyModel property) async {
    await _firestore
        .collection('properties')
        .add(property.toFirestore());
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) async {
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .update({
      ...data,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteProperty(String propertyId) async {
    await _firestore
        .collection('properties')
        .doc(propertyId)
        .delete();
  }

  // Payments
  Stream<List<PaymentModel>> getPaymentsByProperty(String propertyId) {
    return _firestore
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<PaymentModel>> getPaymentsByUser(String userUid,{String? role}) {
    return _firestore
        .collection('payments')
        .where(role??'payerUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => PaymentModel.fromFirestore(doc))
        .toList());
  }

  Future<List<PaymentModel>> getPaymentsByUserFuture(String userUid) async {
     final data =  await _firestore
        .collection('payments')
        .where('payerUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .get();
     return data.docs.map((doc) => PaymentModel.fromFirestore(doc))
         .toList();
  }

  Future<void> addPayment(PaymentModel payment) async {
    await _firestore
        .collection('payments')
        .add(payment.toFirestore());
  }

  Future<void> updatePaymentStatus(String paymentId, String status, {DateTime? paidDate}) async {
    final data = {
      'status': status,
      'lastUpdated': Timestamp.fromDate(DateTime.now()),
    };

    if (paidDate != null) {
      data['paidDate'] = Timestamp.fromDate(paidDate);
    }

    await _firestore
        .collection('payments')
        .doc(paymentId)
        .update(data);
  }

  // Maintenance Requests
  Stream<List<MaintenanceModel>> getMaintenanceByProperty(String propertyId) {
    return _firestore
        .collection('maintenance_requests')
        .where('propertyId', isEqualTo: propertyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MaintenanceModel.fromFirestore(doc))
        .toList());
  }

  Stream<List<MaintenanceModel>> getMaintenanceByUser(String userUid,{String? role}) {
    return _firestore
        .collection('maintenance_requests')
        .where(role??'requesterUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MaintenanceModel.fromFirestore(doc))
        .toList());
  }

  Future<List<MaintenanceModel>> getMaintenanceByUserFuture(String userUid) async{
   final data = await _firestore
        .collection('maintenance_requests')
        .where('requesterUid', isEqualTo: userUid)
        .orderBy('createdAt', descending: true)
        .get();
   return data.docs.map((doc) => MaintenanceModel.fromFirestore(doc),).toList();
  }

  Future<void> addMaintenanceRequest(MaintenanceModel maintenance) async {
    await _firestore
        .collection('maintenance_requests')
        .add(maintenance.toFirestore());
  }

  Future<void> updateMaintenanceStatus(String maintenanceId, String status, {String? assignedTo}) async {
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
  }

  // Dashboard Analytics
  Future<Map<String, dynamic>> getDashboardStats(String? userUid) async {
    final stats = <String, dynamic>{};

    if (userUid != null) {
      // User-specific stats
      final propertiesQuery = await _firestore
          .collection('properties')
          .where('ownerUid', isEqualTo: userUid)
          .get();
      stats['totalProperties'] = propertiesQuery.docs.length;

      final paymentsQuery = await _firestore
          .collection('payments')
          .where('payerUid', isEqualTo: userUid)
          .where('status', isEqualTo: 'pending')
          .get();
      stats['pendingPayments'] = paymentsQuery.docs.length;

      final maintenanceQuery = await _firestore
          .collection('maintenance_requests')
          .where('requesterUid', isEqualTo: userUid)
          .where('status', whereIn: ['pending', 'assigned', 'in_progress'])
          .get();
      stats['activeMaintenanceRequests'] = maintenanceQuery.docs.length;
    } else {
      // Admin stats
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

    return stats;
  }

  // Revenue Analytics
  Future<double> getMonthlyRevenue(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final paymentsQuery = await _firestore
        .collection('payments')
        .where('status', isEqualTo: 'completed')
        .where('paidDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('paidDate', isLessThan: Timestamp.fromDate(endDate))
        .get();

    double totalRevenue = 0;
    for (final doc in paymentsQuery.docs) {
      final payment = PaymentModel.fromFirestore(doc);
      totalRevenue += payment.amount;
    }

    return totalRevenue;
  }

  Future<List<ActivityModel>> getOwnerRecentActivities(String ownerUid) async {
    final activities = <ActivityModel>[];

    // Payments (for properties owned by this owner)
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
            subtitle: '${payment.propertyName} - K ${payment.amount.toStringAsFixed(2)}',
            createdAt: payment.createdAt,
            icon: Icons.payment,
            color: Colors.green,
          ),
        );
      }
    }

    // Maintenance requests (linked to owner properties)
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

    // New Properties registered by this owner
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

    // Sort by date (latest first)
    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return activities.take(10).toList(); // Only return latest 10
  }

}