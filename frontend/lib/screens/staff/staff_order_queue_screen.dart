import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';
import 'staff_order_detail_screen.dart';

class StaffOrderQueueScreen extends StatefulWidget {
  const StaffOrderQueueScreen({super.key});

  @override
  State<StaffOrderQueueScreen> createState() => _StaffOrderQueueScreenState();
}

class _StaffOrderQueueScreenState extends State<StaffOrderQueueScreen> {
  final _orderService = OrderService();
  late Future<List<GasOrder>> _ordersFuture;
  String? _statusFilter;

  final _filters = const [
    {'label': 'All', 'value': null},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Processing', 'value': 'processing'},
    {'label': 'Out for Delivery', 'value': 'out_for_delivery'},
    {'label': 'Delivered', 'value': 'delivered'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _ordersFuture = _orderService.fetchOrders(statusFilter: _statusFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _filters.map((f) {
              final selected = _statusFilter == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f['label'] as String),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _statusFilter = f['value'] as String?;
                    _load();
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => setState(_load),
            child: FutureBuilder<List<GasOrder>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Failed to load orders: ${snapshot.error}'));
                }
                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No orders here.')))],
                  );
                }
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Card(
                      child: ListTile(
                        title: Text('${order.orderNumber} — ${order.customerUsername}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          '${order.orderType == 'purchase' ? 'Purchase' : 'Refill'} • ${order.cylinderTypeName} x${order.quantity}\n'
                          '${DateFormat.yMMMd().add_jm().format(order.createdAt)} • KES ${order.totalAmount.toStringAsFixed(0)}',
                        ),
                        isThreeLine: true,
                        trailing: StatusBadge(status: order.status),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => StaffOrderDetailScreen(orderId: order.id)))
                            .then((_) => setState(_load)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
