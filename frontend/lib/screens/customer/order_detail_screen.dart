import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';
import '../shared/payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  late Future<GasOrder> _orderFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _orderFuture = _orderService.fetchOrder(widget.orderId);
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _orderService.cancelOrder(widget.orderId);
      setState(_load);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not cancel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: FutureBuilder<GasOrder>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load order: ${snapshot.error}'));
          }
          final order = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.orderNumber, style: Theme.of(context).textTheme.titleLarge),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(DateFormat.yMMMd().add_jm().format(order.createdAt), style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Type', order.orderType == 'purchase' ? 'New Purchase' : 'Refill'),
                        _row('Cylinder', order.cylinderTypeName),
                        _row('Quantity', order.quantity.toString()),
                        _row('Delivery Address', order.deliveryAddress),
                        _row('Contact Phone', order.deliveryPhoneNumber),
                        if (order.deliveryNotes?.isNotEmpty == true) _row('Notes', order.deliveryNotes!),
                        const Divider(height: 24),
                        _row('Total Amount', 'KES ${order.totalAmount.toStringAsFixed(0)}', bold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Order Timeline', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...order.statusHistory.map((event) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle, color: Color(0xFF1B6F5C), size: 20),
                      title: Text(_statusLabel(event.status)),
                      subtitle: Text(DateFormat.yMMMd().add_jm().format(event.changedAt) +
                          (event.note?.isNotEmpty == true ? '\n${event.note}' : '')),
                    )),
                const SizedBox(height: 24),
                if (order.status == 'pending')
                  OutlinedButton.icon(
                    onPressed: _cancelOrder,
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                  ),
                if (['pending', 'confirmed', 'processing'].contains(order.status))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PaymentScreen(order: order)),
                      ),
                      icon: const Icon(Icons.payment),
                      label: const Text('Pay for this Order'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) =>
      status.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }
}
