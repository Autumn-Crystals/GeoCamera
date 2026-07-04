import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'photo_gallery_screen.dart';
import 'route_planning_screen.dart';
import 'donor_portal_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(showAppBar: false),
    const PhotoGalleryScreen(showAppBar: false),
    const Placeholder(), // Placeholder for FAB
    const RoutePlanningScreen(showAppBar: false),
    const DonorPortalScreen(showAppBar: false),
  ];

  void _onTabTapped(int index) {
    if (index == 2) {
      // Center FAB - New Plantation
      HapticFeedback.mediumImpact();
      Navigator.pushNamed(context, '/new-entry');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        title: Text(_getTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/qr-scanner');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () async {
              HapticFeedback.lightImpact();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout', style: TextStyle(color: AppTheme.danger)),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onTabTapped(2),
        elevation: 4,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.gradientPrimary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppTheme.bgSecondary,
        elevation: 8,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.photo_library_rounded, 'Gallery'),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(3, Icons.route_rounded, 'Routes'),
              _buildNavItem(4, Icons.people_rounded, 'Donors'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Tree Tracker';
      case 1:
        return 'Photo Gallery';
      case 3:
        return 'Route Planning';
      case 4:
        return 'Donor Portal';
      default:
        return 'Tree Tracker';
    }
  }
}
