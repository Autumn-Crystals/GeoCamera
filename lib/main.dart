import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/new_entry_screen.dart';
import 'screens/update_entry_screen.dart';
import 'screens/tree_detail_screen.dart';
import 'screens/photo_gallery_screen.dart';
import 'screens/route_planning_screen.dart';
import 'screens/donor_portal_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trees_list_screen.dart';
import 'screens/updates_list_screen.dart';
import 'screens/calendar_view_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  await NotificationService.initialize();
  await NotificationService.requestPermissions();
  
  runApp(const GeoCameraApp());
}

class GeoCameraApp extends StatefulWidget {
  const GeoCameraApp({super.key});

  @override
  State<GeoCameraApp> createState() => _GeoCameraAppState();
}

class _GeoCameraAppState extends State<GeoCameraApp> {
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.mobile) || 
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet)) {
        SyncService.syncPendingItems();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoCamera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
        } else if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        } else if (settings.name == '/new-entry') {
          return MaterialPageRoute(builder: (_) => const NewEntryScreen());
        } else if (settings.name == '/update-entry') {
          return MaterialPageRoute(builder: (_) => const UpdateEntryScreen());
        } else if (settings.name == '/gallery') {
          return MaterialPageRoute(builder: (_) => const PhotoGalleryScreen());
        } else if (settings.name == '/route-planning') {
          return MaterialPageRoute(builder: (_) => const RoutePlanningScreen());
        } else if (settings.name == '/donor-portal') {
          return MaterialPageRoute(builder: (_) => const DonorPortalScreen());
        } else if (settings.name == '/qr-scanner') {
          return MaterialPageRoute(builder: (_) => const QRScannerScreen());
        } else if (settings.name == '/settings') {
          return MaterialPageRoute(builder: (_) => const SettingsScreen());
        } else if (settings.name == '/trees-list') {
          return MaterialPageRoute(builder: (_) => const TreesListScreen());
        } else if (settings.name == '/updates-list') {
          return MaterialPageRoute(builder: (_) => const UpdatesListScreen());
        } else if (settings.name == '/calendar-view') {
          return MaterialPageRoute(builder: (_) => const CalendarViewScreen());
        } else if (settings.name?.startsWith('/tree/') == true) {
          final treeId = settings.name!.replaceFirst('/tree/', '');
          return MaterialPageRoute(builder: (_) => TreeDetailScreen(treeId: treeId));
        }
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        if (snapshot.data != null) {
          return const MainNavigationScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
