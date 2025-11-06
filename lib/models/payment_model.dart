import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String propertyId;
  final String propertyOwnerId;
  final String propertyName;
  final String payerUid;
  final String payerName;
  final double amount;
  final String description;
  final String status; // 'pending', 'completed'
  final DateTime createdAt;
  final DateTime paidDate;

  PaymentModel({
    required this.id,
    required this.propertyOwnerId,
    required this.propertyId,
    required this.propertyName,
    required this.payerUid,
    required this.payerName,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.paidDate,
  });

  // Add fromFirestore and toFirestore methods
  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      propertyOwnerId: data['propertyOwnerId'],
      propertyId: data['propertyId'] ?? '',
      propertyName: data['propertyName'] ?? '',
      payerUid: data['payerUid'] ?? '',
      payerName: data['payerName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: DateTime.tryParse(data['createdAt'].toString())??DateTime.now(),
      paidDate: DateTime.tryParse(data['createdAt'].toString())??DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyOwnerId': propertyOwnerId,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'payerUid': payerUid,
      'payerName': payerName,
      'amount': amount,
      'description': description,
      'status': status,
      'createdAt':createdAt.toIso8601String(),
      'paidDate': paidDate.toIso8601String(),
    };
  }
}