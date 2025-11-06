import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/api/local_storage.dart';
import 'package:property_management_system/models/user_model.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/maintenance_model.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:intl/intl.dart';

import 'create_maintenance_request_page.dart';
import 'maintenance_request_detail_screen.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  List<MaintenanceModel> _maintenanceRequests = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRequests();
  }

  Future<void> _loadMaintenanceRequests() async {
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
        await _loadOnlineMaintenance(authProvider, databaseService, user);
      } else {
        // Offline mode - use cached data
        await _loadOfflineMaintenance(user);
      }
    } catch (e) {
      debugPrint('Error loading maintenance requests: $e');
      // Fallback to offline data
      await _loadOfflineMaintenance(user);
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

  Future<void> _loadOnlineMaintenance(
      AuthProvider authProvider,
      DatabaseService databaseService,
      UserModel? user,
      ) async {
    List<MaintenanceModel> requests;

    if (user?.role == 'property_owner') {
      requests = await databaseService.getMaintenanceByUserFuture(user!.uid,isOwner: true);
    } else {
      requests = await databaseService.getMaintenanceByUserFuture(user!.uid);
    }

    setState(() {
      _maintenanceRequests = requests;
    });
  }

  Future<void> _loadOfflineMaintenance(UserModel? user) async {
    final offlineRequests = SharedPreferencesService.getMaintenanceRequests();
    if (offlineRequests != null) {
      final requests = offlineRequests.map((data) {
        return MaintenanceModel(
          id: data['id'] ?? '',
          propertyId: data['propertyId'] ?? '',
          propertyOwnerId: data['propertyOwnerId'] ?? '',
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
          createdAt: DateTime.parse(data['createdAt']),
          completedAt: data['completedAt'] != null
              ? DateTime.parse(data['completedAt'])
              : null,
        );
      }).toList();

      // Filter based on user role
      if (user?.role == 'property_owner') {
        setState(() {
          _maintenanceRequests = requests.where((request) => request.propertyOwnerId == user!.uid).toList();
        });
      } else {
        setState(() {
          _maintenanceRequests = requests.where((request) => request.requesterUid == user!.uid).toList();
        });
      }
    } else {
      setState(() {
        _maintenanceRequests = [];
      });
    }
  }

  void _refreshData() {
    _loadMaintenanceRequests();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'assigned':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isTenant = user?.role == 'tenant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
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
                : _maintenanceRequests.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.build, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _isOffline ? "No cached requests" : "No requests yet",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (!_isOffline && isTenant)
                    const Text(
                      "Create a maintenance request to get started",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _maintenanceRequests.length,
              itemBuilder: (context, index) {
                final request = _maintenanceRequests[index];
                final statusColor = _getStatusColor(request.status);
                final statusText = _getStatusText(request.status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaintenanceDetailScreen(maintenanceRequest: request),
                        ),
                      ).then((updated) {
                        if (updated == true) {
                          _loadMaintenanceRequests();
                        }
                      });
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.build,
                        color: statusColor,
                      ),
                    ),
                    title: Text(
                      request.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.description.length > 50
                              ? '${request.description.substring(0, 50)}...'
                              : request.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(request.createdAt),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            if (_isOffline) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Offline',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isTenant
          ? FloatingActionButton(
        onPressed: () {
          if (_isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot create requests while offline')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMaintenanceScreen()),
          ).then((_) {
            _loadMaintenanceRequests();
          });
        },
        backgroundColor: _isOffline ? Colors.grey : const Color(0xFF1565C0),
        child: Icon(
            Icons.add,
            color: _isOffline ? Colors.grey[400] : Colors.white
        ),
      )
          : null,
    );
  }
}