import 'package:flutter/cupertino.dart';

class ActivityModel {
  final String id;
  final String type; // "payment", "maintenance", "property"
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final IconData icon;
  final Color color;

  ActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.icon,
    required this.color,
  });
}
