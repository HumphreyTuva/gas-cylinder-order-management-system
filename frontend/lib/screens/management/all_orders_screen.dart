import 'package:flutter/material.dart';

import '../staff/staff_order_queue_screen.dart';

/// Standalone wrapper around StaffOrderQueueScreen so it can be pushed as its
/// own page (e.g. from the dashboard's "Orders Today" card) with a proper
/// Scaffold/AppBar/Material ancestor, rather than relying on the shell's
/// existing Scaffold like it does when shown as a bottom-nav tab.
class AllOrdersScreen extends StatelessWidget {
  const AllOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: const StaffOrderQueueScreen(),
    );
  }
}
