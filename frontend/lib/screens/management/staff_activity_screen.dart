import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';

class StaffActivityScreen extends StatefulWidget {
  const StaffActivityScreen({super.key});

  @override
  State<StaffActivityScreen> createState() => _StaffActivityScreenState();
}

class _StaffActivityScreenState extends State<StaffActivityScreen> {
  final _dashboardService = DashboardService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dashboardService.fetchStaffActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Activity')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = Map<String, dynamic>.from(data[index]);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry['staff'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(label: Text(entry['role']), visualDensity: VisualDensity.compact),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          Text('Orders handled: ${entry['orders_handled']}'),
                          Text('Status changes: ${entry['status_changes_made']}'),
                          Text('Deliveries assigned: ${entry['deliveries_assigned']}'),
                          Text('Payments confirmed: ${entry['payments_confirmed']}'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
