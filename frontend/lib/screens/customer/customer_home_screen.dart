import 'package:flutter/material.dart';

import '../../models/cylinder.dart';
import '../../services/cylinder_service.dart';
import 'place_order_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _cylinderService = CylinderService();
  late Future<List<CylinderType>> _catalogueFuture;

  @override
  void initState() {
    super.initState();
    _catalogueFuture = _cylinderService.fetchCatalogue();
  }

  Future<void> _refresh() async {
    setState(() => _catalogueFuture = _cylinderService.fetchCatalogue());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do?', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OrderTypeCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Buy New Cylinder',
                    orderType: 'purchase',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OrderTypeCard(
                    icon: Icons.refresh_rounded,
                    label: 'Refill Cylinder',
                    orderType: 'refill',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Available Cylinders', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder<List<CylinderType>>(
              future: _catalogueFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Could not load cylinders: ${snapshot.error}'),
                  );
                }
                final cylinders = snapshot.data ?? [];
                if (cylinders.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(16), child: Text('No cylinders available right now.'));
                }
                return Column(
                  children: cylinders.map((c) => _CylinderCard(cylinder: c)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String orderType;

  const _OrderTypeCard({required this.icon, required this.label, required this.orderType});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceOrderScreen(orderType: orderType)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 36, color: const Color(0xFF1B6F5C)),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CylinderCard extends StatelessWidget {
  final CylinderType cylinder;
  const _CylinderCard({required this.cylinder});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A1B6F5C),
          child: Icon(Icons.propane_tank_rounded, color: Color(0xFF1B6F5C)),
        ),
        title: Text(cylinder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Purchase: KES ${cylinder.purchasePrice.toStringAsFixed(0)}  •  Refill: KES ${cylinder.refillPrice.toStringAsFixed(0)}'),
        trailing: cylinder.stockQuantity > 0
            ? Text('${cylinder.stockQuantity} in stock', style: const TextStyle(color: Colors.green, fontSize: 12))
            : const Text('Out of stock', style: TextStyle(color: Colors.red, fontSize: 12)),
      ),
    );
  }
}
