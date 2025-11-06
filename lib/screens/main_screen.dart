import 'package:flutter/material.dart';
import 'package:property_management_system/widgets/offline-indicator.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/screens/payments_screen.dart';
import 'package:property_management_system/screens/profile_screen.dart';
import 'package:property_management_system/screens/properties_screen.dart';

import 'dashboard_screen.dart';
import 'maintenance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);

    // Connect auth provider with sync service
    authProvider.setSyncService(syncService);

    // Check connectivity
    await syncService.checkConnectivity();

    // Initial sync if online and user is logged in
    if (syncService.isOnline && authProvider.user != null) {
      try {
        await syncService.syncFromServer(
          authProvider.user!.uid,
          role: authProvider.user!.role,
        );
      } catch (e) {
        debugPrint('Initial sync failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = user?.role == 'admin';
    final isPropertyOwner = user?.role == 'property_owner';
    final isTenant = user?.role == 'tenant';

    final List<Widget> _screens = [
      const DashboardScreen(),
      if (isAdmin || isPropertyOwner) const PropertiesScreen(),
      const PaymentsScreen(),
      const MaintenanceScreen(),
      const ProfileScreen(),
    ];

    // Define navigation items based on user role
    final List<BottomNavigationBarItem> _navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      if (isAdmin || isPropertyOwner)
        const BottomNavigationBarItem(
          icon: Icon(Icons.business),
          label: 'Properties',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.payment),
        label: 'Payments',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.build),
        label: 'Maintenance',
      ),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 20),
          const OfflineIndicator(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey[600],
        items: _navItems,
      ),
    );
  }
}
