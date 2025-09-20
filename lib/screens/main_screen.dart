import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final isAdmin = user?.role == 'admin';
    final isPropertyOwner = user?.role == 'property_owner';
    final isTenant = user?.role == 'tenant';

    // Define screens based on user role
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
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
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