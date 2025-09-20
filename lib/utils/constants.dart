class AppConstants {
  // Property Types
  static const String propertyTypeCommercial = 'commercial';
  static const String propertyTypeResidential = 'residential';
  static const String propertyTypeMixed = 'mixed';

  // User Roles
  static const String rolePropertyOwner = 'property_owner';
  static const String roleCouncilStaff = 'council_staff';
  static const String roleAdmin = 'admin';

  // Payment Methods
  static const String paymentMobileMoney = 'mobile_money';
  static const String paymentBankTransfer = 'bank_transfer';
  static const String paymentCash = 'cash';

  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';

  // Maintenance Status
  static const String maintenanceStatusPending = 'pending';
  static const String maintenanceStatusAssigned = 'assigned';
  static const String maintenanceStatusInProgress = 'in_progress';
  static const String maintenanceStatusCompleted = 'completed';
  static const String maintenanceStatusCancelled = 'cancelled';

  // Maintenance Categories
  static const String maintenancePlumbing = 'plumbing';
  static const String maintenanceElectrical = 'electrical';
  static const String maintenanceStructural = 'structural';
  static const String maintenanceOther = 'other';

  // Maintenance Priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityUrgent = 'urgent';
}
