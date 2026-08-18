import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/notification.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchNotifications();
  }

  Future<void> _refresh() async {
    setState(() => _future = _service.fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _service.markAllRead();
              _refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No notifications yet.')))],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: Icon(
                    _iconFor(n.notificationType),
                    color: n.isRead ? Colors.grey : const Color(0xFF1B6F5C),
                  ),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Text('${n.message}\n${DateFormat.yMMMd().add_jm().format(n.createdAt)}'),
                  isThreeLine: true,
                  onTap: () async {
                    if (!n.isRead) {
                      await _service.markRead(n.id);
                      _refresh();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'order_confirmation':
      case 'order_processing':
        return Icons.receipt_long;
      case 'payment_confirmation':
        return Icons.payments_outlined;
      case 'order_dispatched':
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'delivery_completed':
        return Icons.check_circle_outline;
      case 'order_cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}
