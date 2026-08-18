import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../widgets/status_badge.dart';

class StaffOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const StaffOrderDetailScreen({super.key, required this.orderId});

  @override
  State<StaffOrderDetailScreen> createState() => _StaffOrderDetailScreenState();
}

class _StaffOrderDetailScreenState extends State<StaffOrderDetailScreen> {
  final _orderService = OrderService();
  late Future<GasOrder> _orderFuture;
  bool _updating = false;

  // Mirrors the backend's OrderStatusUpdateSerializer.ALLOWED_TRANSITIONS
  static const Map<String, List<String>> _allowedTransitions = {
    'pending': ['confirmed', 'rejected', 'cancelled'],
    'confirmed': ['processing', 'cancelled'],
    'processing': ['out_for_delivery', 'cancelled'],
    'out_for_delivery': ['delivered', 'failed_delivery'],
    'failed_delivery': ['out_for_delivery', 'cancelled'],
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _orderFuture = _orderService.fetchOrder(widget.orderId);
  }

  Future<void> _assignToMe() async {
    setState(() => _updating = true);
    try {
      await _orderService.assignToMe(widget.orderId);
      setState(_load);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to "${_label(newStatus)}"?'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _updating = true);
    try {
      await _orderService.updateStatus(widget.orderId, newStatus, note: noteController.text.trim());
      setState(_load);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _label(String status) =>
      status.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Process Order')),
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
          final nextStatuses = _allowedTransitions[order.status] ?? [];

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
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Customer', order.customerUsername),
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
                OutlinedButton.icon(
                  onPressed: _updating ? null : _assignToMe,
                  icon: const Icon(Icons.assignment_ind_outlined),
                  label: const Text('Assign to Me'),
                ),
                const SizedBox(height: 20),
                if (nextStatuses.isNotEmpty) ...[
                  Text('Update Status', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: nextStatuses
                        .map((s) => ElevatedButton(
                              onPressed: _updating ? null : () => _updateStatus(s),
                              child: Text(_label(s)),
                            ))
                        .toList(),
                  ),
                ] else
                  const Text('No further status transitions available for this order.'),
                const SizedBox(height: 24),
                Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                ...order.statusHistory.map((e) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle, size: 10, color: Color(0xFF1B6F5C)),
                      title: Text(_label(e.status)),
                      subtitle: Text(
                        '${DateFormat.yMMMd().add_jm().format(e.changedAt)}'
                        '${e.changedByUsername != null ? ' by ${e.changedByUsername}' : ''}'
                        '${e.note?.isNotEmpty == true ? '\n${e.note}' : ''}',
                      ),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

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
