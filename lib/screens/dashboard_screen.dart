import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/models/activity_model.dart';
import 'package:property_management_system/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/models/property_model.dart';
import 'package:property_management_system/models/payment_model.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:intl/intl.dart';
import 'package:property_management_system/api/local_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PropertyModel? _tenantProperty;
  List<PaymentModel> _recentPayments = [];
  Map<String, dynamic> _stats = {};
  List<ActivityModel> _recentActivities = [];
  bool _isLoading = true;
  bool _isPaying = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
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
        await _loadOnlineData(authProvider, databaseService, user);
      } else {
        // Offline mode - use cached data
        await _loadOfflineData(authProvider, user);
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      // Fallback to offline data
      await _loadOfflineData(authProvider, user);
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

  Future<void> _loadOnlineData(
    AuthProvider authProvider,
    DatabaseService databaseService,
    UserModel? user,
  ) async {
    if (user?.role == 'tenant') {
      // Load tenant data
      final properties = await databaseService.getAllPropertiesFuture();
      _tenantProperty = properties.firstWhere(
        (property) => property.isOccupied && property.tenantId == user!.uid,
        orElse: () => PropertyModel(
          id: '',
          name: 'No Property Assigned',
          ownerUid: '',
          ownerName: '',
          address: '',
          type: '',
          monthlyRent: 0,
          isOccupied: false,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        ),
      );

      _recentPayments = await databaseService.getPaymentsByUserFuture(
        user!.uid,
      );
    } else {
      // Load admin/owner data
      _stats = await databaseService.getDashboardStats(
        authProvider.user!.uid,
        isAdmin: user?.role == 'admin' || user?.role == "property_owner",
      );
      _recentActivities = await databaseService.getOwnerRecentActivities(
        user!.uid,
      );
    }
  }

  Future<void> _loadOfflineData(
    AuthProvider authProvider,
    UserModel? user,
  ) async {
    if (user?.role == 'tenant') {
      // Load tenant offline data
      final offlineProperties = SharedPreferencesService.getProperties();
      if (offlineProperties != null) {
        final properties = offlineProperties.map((data) {
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

        _tenantProperty = properties.firstWhere(
          (property) => property.isOccupied && property.tenantId == user!.uid,
          orElse: () => PropertyModel(
            id: '',
            name: 'No Property Assigned',
            ownerUid: '',
            ownerName: '',
            address: '',
            type: '',
            monthlyRent: 0,
            isOccupied: false,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        );
      }

      // Load offline payments
      final offlinePayments = SharedPreferencesService.getPayments();
      if (offlinePayments != null) {
        _recentPayments = offlinePayments
            .map((data) {
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
            })
            .where((payment) => payment.payerUid == user!.uid)
            .toList();
      }
    } else {
      // Load admin/owner offline data
      _stats =
          SharedPreferencesService.getDashboardStats() ??
          {
            'totalProperties': 0,
            'pendingPayments': 0,
            'monthlyRevenue': 0,
            'activeMaintenanceRequests': 0,
          };

      // Load offline activities
      final offlineActivities = SharedPreferencesService.getRecentActivities();
      if (offlineActivities != null) {
        _recentActivities = offlineActivities.map((data) {
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
    }
  }

  Future<void> _makePayment() async {
    if (_tenantProperty == null) return;

    setState(() => _isPaying = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final syncService = Provider.of<SyncService>(context, listen: false);
      final user = authProvider.user;

      final payment = PaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        propertyId: _tenantProperty!.id,
        propertyOwnerId: _tenantProperty!.ownerUid,
        propertyName: _tenantProperty!.name,
        payerUid: user!.uid,
        payerName: user.name,
        amount: _tenantProperty!.monthlyRent,
        description: 'Monthly Rent Payment',
        status: 'completed',
        createdAt: DateTime.now(),
        paidDate: DateTime.now(),
      );

      if (_isOffline) {
        // Queue payment for sync when online
        await syncService.queueOperation(
          type: 'payment',
          operation: 'add',
          data: payment.toFirestore(),
        );

        // Update local state immediately
        setState(() {
          _recentPayments.insert(0, payment);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment queued for sync when online!')),
        );
      } else {
        // Online payment
        final databaseService = DatabaseService();
        await databaseService.addPayment(payment);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));

        _loadDashboardData(); // Reload to get updated data
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  void _refreshData() {
    _loadDashboardData();
  }

  Widget _buildTenantDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final now = DateTime.now();

    bool hasPaid = _recentPayments.any(
      (payment) =>
          payment.paidDate.month == now.month &&
          payment.paidDate.year == now.year,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card with offline indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Welcome, Tenant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 14,
                              color: Colors.orange[800],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Chililabombwe Municipal Council',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Property Details Card
          if (_tenantProperty != null && _tenantProperty!.id.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Property',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPropertyInfo('Name', _tenantProperty!.name),
                    _buildPropertyInfo('Address', _tenantProperty!.address),
                    _buildPropertyInfo('Type', _tenantProperty!.type),
                    _buildPropertyInfo(
                      'Monthly Rent',
                      'K ${_tenantProperty!.monthlyRent.toStringAsFixed(2)}',
                    ),
                    _buildPropertyInfo(
                      'Status',
                      _tenantProperty!.isOccupied ? 'Occupied' : 'Vacant',
                      statusColor: _tenantProperty!.isOccupied
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              ),
            )
          else
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No property assigned to you yet.'),
              ),
            ),

          const SizedBox(height: 24),

          // Payment Section
          if (_tenantProperty != null && _tenantProperty!.id.isNotEmpty)
            hasPaid
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      spacing: 10,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        Text(
                          "Payment made for this month",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Make Payment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Monthly Rent:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'K ${_tenantProperty!.monthlyRent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Due Date: 5th of each month',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isPaying ? null : _makePayment,
                              child: _isPaying
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      _isOffline
                                          ? 'Go online to pay'
                                          : 'Pay Now',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

          const SizedBox(height: 24),

          // Recent Payments
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Recent Payments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isOffline) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cached',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _recentPayments.isEmpty
                      ? const Text('No recent payments')
                      : Column(
                          children: _recentPayments
                              .take(3)
                              .map((payment) => _buildPaymentItem(payment))
                              .toList(),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isTenant = authProvider.user?.role == 'tenant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
        ],
      ),
      body: isTenant ? _buildTenantDashboard() : _buildAdminDashboard(),
    );
  }

  Widget _buildAdminDashboard() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card with offline indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Welcome, Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isOffline)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cloud_off,
                                    size: 14,
                                    color: Colors.orange[800],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Offline',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chililabombwe Municipal Council',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    _buildStatCard(
                      title: 'Total Properties',
                      value: '${_stats['totalProperties'] ?? 0}',
                      icon: Icons.business,
                      color: Colors.blue,
                    ),
                    _buildStatCard(
                      title: 'Pending Payments',
                      value: '${_stats['pendingPayments'] ?? 0}',
                      icon: Icons.payment,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      title: 'This Month Revenue',
                      value: 'K ${_stats['monthlyRevenue'] ?? 0}',
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                    _buildStatCard(
                      title: 'Maintenance Requests',
                      value: '${_stats['activeMaintenanceRequests'] ?? 0}',
                      icon: Icons.build,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Activities
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Recent Activities',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_isOffline) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Cached',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentActivities.isEmpty
                            ? const Text('No recent activities')
                            : Column(
                                children: _recentActivities
                                    .take(5)
                                    .map(
                                      (activity) =>
                                          _buildActivityItem(activity),
                                    )
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildPropertyInfo(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: statusColor ?? Colors.black,
              fontWeight: statusColor != null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(PaymentModel payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(payment.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'K ${payment.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: payment.status == 'completed'
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityModel activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.notifications, color: Colors.blue[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(activity.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
