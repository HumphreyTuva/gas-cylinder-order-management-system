import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _orderService = OrderService();
  late Future<List<GasOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _orderService.fetchOrders();
  }

  Future<void> _refresh() async {
    setState(() => _ordersFuture = _orderService.fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
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
              children: const [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('You have no orders yet.')),
                ),
              ],
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
                  title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${order.orderType == 'purchase' ? 'Purchase' : 'Refill'} • ${order.cylinderTypeName} x${order.quantity}\n'
                    '${DateFormat.yMMMd().add_jm().format(order.createdAt)}',
                  ),
                  isThreeLine: true,
                  trailing: StatusBadge(status: order.status),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
                  ).then((_) => _refresh()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
