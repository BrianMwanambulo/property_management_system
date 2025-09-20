import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:property_management_system/models/user_model.dart';

class PropertyModel {
  final String id;
  final String name;
  final String ownerUid;
  final String? tenantId;
  final UserModel? tenant;
  final String ownerName;
  final String address;
  final String type; // 'commercial', 'residential', 'mixed'
  final double monthlyRent;
  final bool isOccupied;
  final GeoPoint? location;
  final List<String> images;
  final DateTime createdAt;
  final DateTime lastUpdated;

  PropertyModel({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.ownerName,
    required this.address,
    required this.type,
    required this.monthlyRent,
    required this.isOccupied,
    this.location,
    this.tenant,
    this.tenantId,
    this.images = const [],
    required this.createdAt,
    required this.lastUpdated,
  });

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PropertyModel(
      id: doc.id,
      name: data['name'] ?? 'Property #${doc.id.substring(0, 8)}',
      ownerUid: data['ownerUid'] ?? '',
      ownerName: data['ownerName'] ?? '',
      tenantId: data['tenantId'],
      tenant: data['tenant'] != null? UserModel.fromFirestore(data['tenant'],data['tenantId']):null,
      address: data['address'] ?? '',
      type: data['type'] ?? 'commercial',
      monthlyRent: (data['monthlyRent'] ?? 0).toDouble(),
      isOccupied: data['isOccupied'] ?? false,
      location: data['location'],
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'address': address,
      'type': type,
      'tenant': tenant?.toFirestore(),
      'tenantId': tenantId,
      'monthlyRent': monthlyRent,
      'isOccupied': isOccupied,
      'location': location,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}