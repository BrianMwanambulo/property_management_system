import 'package:flutter/material.dart';
import 'package:property_management_system/api/database_service.dart';
import 'package:property_management_system/screens/add_property_screen.dart';
import 'package:property_management_system/screens/property_details_screen.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/models/property_model.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  List<PropertyModel> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final databaseService = DatabaseService();

    try {
      List<PropertyModel> properties;

      if (user?.role == 'admin') {
        // Admin can see all properties
        properties = await databaseService.getAllProperties().first;
      } else {
        // Property owners see only their properties
        properties = await databaseService.getPropertiesByOwner(user!.uid).first;
      }

      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load properties: $e')),
      );
    }
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
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _properties.isEmpty? Center(child: Text("No properties yet. Add some."),) : ListView.builder(
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
                    builder: (context) => PropertyDetailsScreen(property: property),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: property.isOccupied ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          property.isOccupied ? 'Occupied' : 'Vacant',
                          style: TextStyle(
                            fontSize: 12,
                            color: property.isOccupied ? Colors.green[800] : Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          );
        },
      ),
      floatingActionButton: (isAdmin || isPropertyOwner)
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPropertyScreen()),
          ).then((_) {
            _loadProperties();
          });
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}