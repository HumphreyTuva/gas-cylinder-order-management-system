import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../widgets/status_badge.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = PaymentService();
  late Future<List<Payment>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchPayments();
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Payment>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load: ${snapshot.error}'));
            }
            final payments = snapshot.data ?? [];
            if (payments.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No transactions yet.')))],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                final p = payments[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0x1A1B6F5C),
                      child: Icon(
                        p.method == 'mpesa' ? Icons.phone_android : Icons.credit_card,
                        color: const Color(0xFF1B6F5C),
                      ),
                    ),
                    title: Text('${p.orderNumber} • KES ${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${p.method == 'mpesa' ? 'M-Pesa' : 'Card'} • ${DateFormat.yMMMd().add_jm().format(p.createdAt)}'
                      '${p.transactionReference?.isNotEmpty == true ? '\nRef: ${p.transactionReference}' : ''}',
                    ),
                    isThreeLine: p.transactionReference?.isNotEmpty == true,
                    trailing: StatusBadge(status: p.status),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
