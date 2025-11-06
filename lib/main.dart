import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:property_management_system/api/sync_service.dart';
import 'package:property_management_system/firebase_options.dart';
import 'package:property_management_system/providers/auth_provider.dart';
import 'package:property_management_system/providers/payment_provider.dart';
import 'package:property_management_system/providers/property_provider.dart';
import 'package:property_management_system/screens/auth/login.dart';
import 'package:property_management_system/screens/main_screen.dart';
import 'package:property_management_system/screens/maintenance_screen.dart';
import 'package:property_management_system/screens/payments_screen.dart';
import 'package:property_management_system/screens/profile_screen.dart';
import 'package:property_management_system/screens/properties_screen.dart';
import 'package:property_management_system/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:property_management_system/api/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SharedPreferencesService.init();
  runApp(const PropertyManagementApp());
}

class PropertyManagementApp extends StatelessWidget {
  const PropertyManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => PropertyProvider()),
        ChangeNotifierProvider(create: (context) => PaymentProvider()),
        ChangeNotifierProvider(create: (context) => SyncService()),
      ],
      child: MaterialApp(
        title: 'PMS - Chililabombwe',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.grey.shade50,
          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            elevation: 0,
          ),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const MainScreen(),
          '/properties': (context) => const PropertiesScreen(),
          '/payments': (context) => const PaymentsScreen(),
          '/maintenance': (context) => const MaintenanceScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}