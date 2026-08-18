import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cylinder.dart';
import '../../providers/auth_provider.dart';
import '../../services/cylinder_service.dart';
import '../../services/order_service.dart';
import '../../widgets/loading_button.dart';
import 'order_detail_screen.dart';

class PlaceOrderScreen extends StatefulWidget {
  final String orderType; // purchase | refill
  const PlaceOrderScreen({super.key, required this.orderType});

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cylinderService = CylinderService();
  final _orderService = OrderService();

  List<CylinderType> _cylinders = [];
  CylinderType? _selected;
  int _quantity = 1;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _loadingCatalogue = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _addressController.text = user?.defaultDeliveryAddress ?? '';
    _phoneController.text = user?.phoneNumber ?? '';
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    try {
      final cylinders = await _cylinderService.fetchCatalogue();
      setState(() {
        _cylinders = cylinders.where((c) => c.isActive).toList();
        _selected = _cylinders.isNotEmpty ? _cylinders.first : null;
        _loadingCatalogue = false;
      });
    } catch (e) {
      setState(() => _loadingCatalogue = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load cylinders: $e')));
      }
    }
  }

  double get _estimatedTotal {
    if (_selected == null) return 0;
    final unitPrice = widget.orderType == 'purchase' ? _selected!.purchasePrice : _selected!.refillPrice;
    return unitPrice * _quantity;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _submitting = true);
    try {
      final order = await _orderService.placeOrder(
        orderType: widget.orderType,
        cylinderTypeId: _selected!.id,
        quantity: _quantity,
        deliveryAddress: _addressController.text.trim(),
        deliveryPhoneNumber: _phoneController.text.trim(),
        deliveryNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not place order: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.orderType == 'purchase' ? 'Buy New Cylinder' : 'Request Refill';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loadingCatalogue
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('1. Select Cylinder', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<CylinderType>(
                        value: _selected,
                        items: _cylinders
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    '${c.name} — KES ${(widget.orderType == 'purchase' ? c.purchasePrice : c.refillPrice).toStringAsFixed(0)}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selected = v),
                        validator: (v) => v == null ? 'Please select a cylinder' : null,
                      ),
                      const SizedBox(height: 20),
                      Text('2. Quantity', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
                          ),
                          IconButton.filledTonal(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('3. Delivery Details', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Delivery Address', prefixIcon: Icon(Icons.location_on_outlined)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Contact Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(labelText: 'Delivery Notes (optional)', prefixIcon: Icon(Icons.note_outlined)),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: const Color(0x0D1B6F5C),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                'KES ${_estimatedTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B6F5C)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LoadingButton(label: 'Review & Submit Order', loading: _submitting, onPressed: _submit),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
