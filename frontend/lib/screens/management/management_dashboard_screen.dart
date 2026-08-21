import 'package:flutter/material.dart';

import '../../services/dashboard_service.dart';
import '../../widgets/status_badge.dart';
import 'all_orders_screen.dart';
import 'customer_list_screen.dart';
import 'staff_management_screen.dart';
import 'transactions_screen.dart';

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({super.key});

  @override
  State<ManagementDashboardScreen> createState() => _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  final _dashboardService = DashboardService();
  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _dashboardService.fetchSummary();
  }

  Future<void> _refresh() async {
    setState(() => _summaryFuture = _dashboardService.fetchSummary());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load dashboard: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final totals = Map<String, dynamic>.from(data['totals']);
          final ordersByStatus = Map<String, dynamic>.from(data['orders_by_status'] ?? {});
          final recentOrders = List<dynamic>.from(data['recent_orders'] ?? []);
          final recentTransactions = List<dynamic>.from(data['recent_transactions'] ?? []);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _StatCard(
                    label: 'Customers',
                    value: '${totals['customers']}',
                    icon: Icons.people_outline,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                    ),
                  ),
                  _StatCard(
                    label: 'Staff',
                    value: '${totals['staff']}',
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
                    ),
                  ),
                  _StatCard(
                    label: 'Orders Today',
                    value: '${totals['orders_today']}',
                    icon: Icons.today_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AllOrdersScreen()),
                    ),
                  ),
                  _StatCard(
                    label: 'Revenue Today',
                    value: 'KES ${totals['revenue_today']}',
                    icon: Icons.payments_outlined,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Orders by Status', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ordersByStatus.entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Chip(
                              avatar: StatusBadge(status: e.key),
                              label: Text('${e.value}'),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              _RecentActivitySection(recentOrders: recentOrders, recentTransactions: recentTransactions),
            ],
          );
        },
      ),
    );
  }
}

/// Shows Recent Orders and Recent Transactions as two tabs side by side
/// instead of one long stacked list -- Recent Orders is shown by default.
class _RecentActivitySection extends StatefulWidget {
  final List<dynamic> recentOrders;
  final List<dynamic> recentTransactions;
  const _RecentActivitySection({required this.recentOrders, required this.recentTransactions});

  @override
  State<_RecentActivitySection> createState() => _RecentActivitySectionState();
}

class _RecentActivitySectionState extends State<_RecentActivitySection> {
  bool _showTransactions = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleTab(
                label: 'Recent Orders',
                selected: !_showTransactions,
                onTap: () => setState(() => _showTransactions = false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ToggleTab(
                label: 'Recent Transactions',
                selected: _showTransactions,
                onTap: () => setState(() => _showTransactions = true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!_showTransactions)
          if (widget.recentOrders.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No recent orders.'))
          else
            ...widget.recentOrders.map((o) => Card(
                  child: ListTile(
                    title: Text('${o['order_number']} — ${o['customer']}'),
                    subtitle: Text('${o['cylinder_type']} • KES ${o['total_amount']}'),
                    trailing: StatusBadge(status: o['status']),
                  ),
                ))
        else if (widget.recentTransactions.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No recent transactions.'))
        else
          ...widget.recentTransactions.map((p) => Card(
                child: ListTile(
                  title: Text('${p['order_number']} — ${p['customer']}'),
                  subtitle: Text('${(p['method'] as String).toUpperCase()} • KES ${p['amount']}'),
                  trailing: StatusBadge(status: p['status']),
                ),
              )),
      ],
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1B6F5C) : const Color(0x0D1B6F5C),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1B6F5C),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const _StatCard({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: const Color(0xFF1B6F5C)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
