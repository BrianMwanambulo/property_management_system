import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/maintenance_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRequests();
  }

  Future<void> _loadMaintenanceRequests() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final databaseService = DatabaseService();

    try {
      List<MaintenanceModel> requests;

      if (user?.role == 'property_owner') {
        // Admin can see all requests
        // Note: You might need to implement getAllMaintenanceRequests in DatabaseService
        requests = await databaseService.getMaintenanceByUser(user!.uid,role: "propertyOwnerId").first; // Placeholder
      } else {
        // Regular users see only their requests
        requests = await databaseService.getMaintenanceByUser(user!.uid).first;
      }

      setState(() {
        _maintenanceRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load maintenance requests: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isTenant = user?.role == 'tenant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
      ),
      body:SafeArea(
        child: _maintenanceRequests.isEmpty? Center(child: Text("No requests yet."),) :   _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _maintenanceRequests.length,
          itemBuilder: (context, index) {
            final request = _maintenanceRequests[index];
            final statusColors = {
              'pending': Colors.orange,
              'in_progress': Colors.blue,
              'completed': Colors.green,
            };
        
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                // In your maintenance_screen.dart, update the ListTile onTap:
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MaintenanceDetailScreen(maintenanceRequest: request),
                    ),
                  ).then((updated) {
                    if (updated == true) {
                      // Refresh the maintenance requests list when returning from detail screen
                      _loadMaintenanceRequests();
                    }
                  });
                },
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColors[request.status]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.build,
                    color: statusColors[request.status] ?? Colors.grey,
                  ),
                ),
                title: Text('Request #${request.requesterName.substring(0, 8)}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.description),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColors[request.status]?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        request.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColors[request.status] ?? Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        ),
      ),
      floatingActionButton:   isTenant
        ? FloatingActionButton(
        onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateMaintenanceScreen()),
      ).then((_) {
        _loadMaintenanceRequests();
      });
    },
    backgroundColor: const Color(0xFF1565C0),
    child: const Icon(Icons.add, color: Colors.white),
    )
        : null,
    );
  }
}