import 'package:flutter/foundation.dart';
import '../api/database_service.dart';
import '../api/payment_service.dart';
import '../models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<PaymentModel> _payments = [];
  bool _isLoading = false;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;

  Future<void> loadPaymentsByUser(String userUid) async {
    _isLoading = true;
    notifyListeners();

    try {
      _databaseService.getPaymentsByUser(userUid).listen((payments) {
        _payments = payments;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }
  }

  Future<Map<String, dynamic>> processPayment({
    required PaymentModel payment,
    required String phoneNumber,
    required String provider,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add payment to database first
      await _databaseService.addPayment(payment);

      // Initiate payment with provider
      final paymentResult = await PaymentService.initiateMobileMoneyPayment(
        phoneNumber: phoneNumber,
        amount: payment.amount,
        reference: payment.id,
        provider: provider,
      );

      _isLoading = false;
      notifyListeners();
      return paymentResult;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e.toString();
    }
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _databaseService.updatePaymentStatus(
        paymentId,
        status,
        paidDate: status == 'completed' ? DateTime.now() : null,
      );
    } catch (e) {
      throw e.toString();
    }
  }
}