import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/api/local_storage.dart';
import 'package:property_management_system/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/payment_model.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);
    final databaseService = DatabaseService();
    final user = authProvider.user;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check connectivity first
      final isOnline = await syncService.checkConnectivity();
      setState(() {
        _isOffline = !isOnline;
      });

      if (isOnline) {
        // Online mode - fetch fresh data
        await _loadOnlinePayments(authProvider, databaseService, user);
      } else {
        // Offline mode - use cached data
        await _loadOfflinePayments(user);
      }
    } catch (e) {
      debugPrint('Error loading payments: $e');
      // Fallback to offline data
      await _loadOfflinePayments(user);
      setState(() {
        _isOffline = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline mode: Using cached data')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadOnlinePayments(
    AuthProvider authProvider,
    DatabaseService databaseService,
    UserModel? user,
  ) async {
    List<PaymentModel> payments;

    if (user?.role == 'property_owner') {
      payments = await databaseService.getPaymentsByUserFuture(
        user!.uid,
        isOwner: true,
      );
    } else {
      payments = await databaseService.getPaymentsByUserFuture(user!.uid);
    }

    setState(() {
      _payments = payments;
    });
  }

  Future<void> _loadOfflinePayments(UserModel? user) async {
    final offlinePayments = SharedPreferencesService.getPayments();
    if (offlinePayments != null) {
      final payments = offlinePayments.map((data) {
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

      // Filter based on user role
      if (user?.role == 'property_owner') {
        setState(() {
          _payments = payments
              .where((payment) => payment.propertyOwnerId == user!.uid)
              .toList();
        });
      } else {
        setState(() {
          _payments = payments
              .where((payment) => payment.payerUid == user!.uid)
              .toList();
        });
      }
    } else {
      setState(() {
        _payments = [];
      });
    }
  }

  void _refreshData() {
    _loadPayments();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Payments'),
        actions: [
          if (_isOffline)
            IconButton(
              icon: const Icon(Icons.cloud_off, color: Colors.orange),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You are currently offline')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Mode - Showing cached data',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _payments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.payment, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _isOffline
                              ? "No cached payments"
                              : "No payments available",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            final statusColor = _getStatusColor(payment.status);
                            final statusIcon = _getStatusIcon(payment.status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    statusIcon,
                                    color: statusColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  payment.description,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      payment.propertyName,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'MMM dd, yyyy',
                                      ).format(payment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'K ${payment.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        payment.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (_isOffline) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Offline',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.orange[800],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
