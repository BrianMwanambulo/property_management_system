import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/screens/add_property_screen.dart';
import 'package:property_management_system/screens/property_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/property_model.dart';
import 'package:property_management_system/api/sync_service.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  List<PropertyModel> _properties = [];
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);
    final user = authProvider.user;
    final databaseService = DatabaseService();

    setState(() {
      _isLoading = true;
      _isOffline = !syncService.isOnline;
    });

    try {
      List<PropertyModel> properties;

      if (user?.role == 'admin') {
        properties = await databaseService.getAllProperties().first;
      } else {
        properties = await databaseService
            .getPropertiesByOwner(user!.uid)
            .first;
      }

      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      try {
        final offlineProperties = await databaseService
            .getAllPropertiesFuture();
        setState(() {
          _properties = offlineProperties;
          _isLoading = false;
          _isOffline = true;
        });
      } catch (offlineError) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Offline mode: Using cached data')),
        );
      }
    }
  }

  void _refreshData() {
    _loadProperties();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = user?.role == 'admin';
    final isPropertyOwner = user?.role == 'property_owner';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
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
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Implement filter
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
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
                : _properties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.business,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isOffline
                              ? "No cached properties"
                              : "No properties yet",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        if (!_isOffline)
                          const Text(
                            "Add some properties to get started",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _properties.length,
                    itemBuilder: (context, index) {
                      final property = _properties[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PropertyDetailsScreen(property: property),
                              ),
                            ).then((_) {
                              _loadProperties();
                            });
                          },
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          title: Text(property.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${property.address} - ${property.type}'),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: property.isOccupied
                                          ? Colors.green[100]
                                          : Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      property.isOccupied
                                          ? 'Occupied'
                                          : 'Vacant',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: property.isOccupied
                                            ? Colors.green[800]
                                            : Colors.red[800],
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                        'Offline',
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
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: (isAdmin || isPropertyOwner)
          ? FloatingActionButton(
              onPressed: () {
                if (_isOffline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot create properties while offline'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPropertyScreen(),
                  ),
                ).then((_) {
                  _loadProperties();
                });
              },
              backgroundColor: _isOffline
                  ? Colors.grey
                  : const Color(0xFF1565C0),
              child: Icon(
                Icons.add,
                color: _isOffline ? Colors.grey[400] : Colors.white,
              ),
            )
          : null,
    );
  }
}
