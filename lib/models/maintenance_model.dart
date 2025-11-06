import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceModel {
  final String id;
  final String propertyId;
  final String propertyOwnerId;
  final String propertyNumber;
  final String requesterUid;
  final String requesterName;
  final String title;
  final String description;
  final String category; // 'plumbing', 'electrical', 'structural', 'other'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String
  status; // 'pending', 'assigned', 'in_progress', 'completed', 'cancelled'
  final List<String> images;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? completedAt;

  MaintenanceModel({
    required this.id,
    required this.propertyOwnerId,
    required this.propertyId,
    required this.propertyNumber,
    required this.requesterUid,
    required this.requesterName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.images = const [],
    this.assignedTo,
    required this.createdAt,
    this.completedAt,
  });

  factory MaintenanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaintenanceModel(
      id: doc.id,
      propertyOwnerId: data['propertyOwnerId'] ?? "",
      propertyId: data['propertyId'] ?? '',
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
      createdAt:
          DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now(),
      completedAt:
          DateTime.tryParse(data['completedAt'].toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'propertyNumber': propertyNumber,
      'propertyOwnerId': propertyOwnerId,
      'requesterUid': requesterUid,
      'requesterName': requesterName,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'images': images,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
