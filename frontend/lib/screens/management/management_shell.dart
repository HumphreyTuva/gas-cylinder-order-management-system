import 'package:flutter/material.dart';

import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import '../staff/staff_order_queue_screen.dart';
import 'cylinder_management_screen.dart';
import 'management_dashboard_screen.dart';
import 'staff_activity_screen.dart';
import 'staff_management_screen.dart';

class ManagementShell extends StatefulWidget {
  const ManagementShell({super.key});

  @override
  State<ManagementShell> createState() => _ManagementShellState();
}

class _ManagementShellState extends State<ManagementShell> {
  int _index = 0;

  final _screens = const [
    ManagementDashboardScreen(),
    StaffOrderQueueScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  final _titles = const ['Management Dashboard', 'All Orders', 'Notifications', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (_index == 2 || _index == 3)
          ? null
          : AppBar(
              title: Text(_titles[_index]),
              actions: _index == 0
                  ? [
                      IconButton(
                        icon: const Icon(Icons.propane_tank_outlined),
                        tooltip: 'Manage Cylinders',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CylinderManagementScreen()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.badge_outlined),
                        tooltip: 'Manage Staff',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.people_alt_outlined),
                        tooltip: 'Staff Activity',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StaffActivityScreen()),
                        ),
                      ),
                    ]
                  : null,
            ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
