import 'package:flutter/material.dart';
import 'package:property_management_system/api/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/providers/auth_provider.dart';

import 'auth/login.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name.substring(0, 2).toUpperCase()
                          : 'US',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.role?.replaceAll('_', ' ').toUpperCase() ?? 'USER ROLE',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.phone ?? 'No phone number',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Profile Options
            _buildProfileOption(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.security,
              title: 'Security',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.info,
              title: 'About',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                try {
                  await authService.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: textColor ?? Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}