import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/payment_model.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final databaseService = DatabaseService();

    try {
      List<PaymentModel> payments;

      if (user?.role == 'property_owner') {
        // Admin can see all payments
        // Note: You might need to implement getAllPayments in DatabaseService
        payments =   payments = await databaseService.getPaymentsByUser(user!.uid,role: "propertyOwnerId").first; // Placeholder
      } else {
        // Regular users see only their payments
        payments = await databaseService.getPaymentsByUser(user!.uid).first;
      }

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load payments: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Payments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          :_payments.isEmpty?  Center(child: Text("No Payments available"),) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Methods
            // if (isTenant) ...[
            //   const Text(
            //     'Payment Methods',
            //     style: TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            //   const SizedBox(height: 16),
            //   Row(
            //     children: [
            //       Expanded(
            //         child: _buildPaymentMethodCard(
            //           'Mobile Money',
            //           Icons.phone_android,
            //           Colors.orange,
            //         ),
            //       ),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: _buildPaymentMethodCard(
            //           'Bank Transfer',
            //           Icons.account_balance,
            //           Colors.blue,
            //         ),
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 24),
            // ],

            // // Recent Transactions
            // const Text(
            //   'Recent Transactions',
            //   style: TextStyle(
            //     fontSize: 18,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 16),

             ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: payment.status == 'completed'
                            ? Colors.green[100]
                            : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        payment.status == 'completed'
                            ? Icons.check_circle
                            : Icons.pending,
                        color: payment.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text('Property #${payment.propertyId.substring(0, 8)}'),
                    subtitle: Text('${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}'),
                    trailing: Text(
                      'K ${payment.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: payment.status == 'completed'
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String title, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}