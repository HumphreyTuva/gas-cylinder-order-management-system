import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/staff_service.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _service = StaffService();
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchCustomers();
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<AppUser>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load: ${snapshot.error}'));
            }
            final customers = snapshot.data ?? [];
            if (customers.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No customers yet.')))],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0x1A1B6F5C),
                      child: Text(
                        customer.username.isNotEmpty ? customer.username[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF1B6F5C)),
                      ),
                    ),
                    title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '@${customer.username} • ${customer.phoneNumber}'
                      '${customer.defaultDeliveryAddress?.isNotEmpty == true ? '\n${customer.defaultDeliveryAddress}' : ''}',
                    ),
                    isThreeLine: customer.defaultDeliveryAddress?.isNotEmpty == true,
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
