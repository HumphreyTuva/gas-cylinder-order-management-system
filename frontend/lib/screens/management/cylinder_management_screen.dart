import 'package:flutter/material.dart';

import '../../models/cylinder.dart';
import '../../services/cylinder_service.dart';
import '../../widgets/loading_button.dart';

class CylinderManagementScreen extends StatefulWidget {
  const CylinderManagementScreen({super.key});

  @override
  State<CylinderManagementScreen> createState() => _CylinderManagementScreenState();
}

class _CylinderManagementScreenState extends State<CylinderManagementScreen> {
  final _service = CylinderService();
  late Future<List<CylinderType>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchCatalogue();
  }

  void _refresh() {
    setState(() {
      _future = _service.fetchCatalogue();
    });
  }

  Future<void> _openForm({CylinderType? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CylinderFormSheet(existing: existing),
    );
    if (saved == true) _refresh();
  }

  Future<void> _delete(CylinderType cylinder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cylinder Type'),
        content: Text('Remove "${cylinder.name}" from the catalogue? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteCylinderType(cylinder.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete (it may be referenced by existing orders): $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Cylinders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Cylinder'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<CylinderType>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Failed to load: ${snapshot.error}'));
            }
            final cylinders = snapshot.data ?? [];
            if (cylinders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No cylinder types yet. Tap + to add one.')))],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: cylinders.length,
              itemBuilder: (context, index) {
                final c = cylinders[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.isActive ? const Color(0x1A1B6F5C) : Colors.grey.shade200,
                      child: const Icon(Icons.propane_tank_rounded, color: Color(0xFF1B6F5C)),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Purchase KES ${c.purchasePrice.toStringAsFixed(0)} • Refill KES ${c.refillPrice.toStringAsFixed(0)}\n'
                      'Stock: ${c.stockQuantity}${c.isActive ? '' : ' • Inactive'}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _openForm(existing: c);
                        if (value == 'delete') _delete(c);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
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

class _CylinderFormSheet extends StatefulWidget {
  final CylinderType? existing;
  const _CylinderFormSheet({this.existing});

  @override
  State<_CylinderFormSheet> createState() => _CylinderFormSheetState();
}

class _CylinderFormSheetState extends State<_CylinderFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _service = CylinderService();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _sizeKg = TextEditingController(text: widget.existing?.sizeKg.toString() ?? '');
  late final _purchasePrice = TextEditingController(text: widget.existing?.purchasePrice.toString() ?? '');
  late final _refillPrice = TextEditingController(text: widget.existing?.refillPrice.toString() ?? '');
  late final _stock = TextEditingController(text: widget.existing?.stockQuantity.toString() ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late bool _isActive = widget.existing?.isActive ?? true;

  bool _saving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await _service.createCylinderType(
          name: _name.text.trim(),
          sizeKg: double.parse(_sizeKg.text),
          purchasePrice: double.parse(_purchasePrice.text),
          refillPrice: double.parse(_refillPrice.text),
          stockQuantity: int.parse(_stock.text),
          description: _description.text.trim(),
          isActive: _isActive,
        );
      } else {
        await _service.updateCylinderType(
          widget.existing!.id,
          name: _name.text.trim(),
          sizeKg: double.parse(_sizeKg.text),
          purchasePrice: double.parse(_purchasePrice.text),
          refillPrice: double.parse(_refillPrice.text),
          stockQuantity: int.parse(_stock.text),
          description: _description.text.trim(),
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Edit Cylinder Type' : 'Add Cylinder Type', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name (e.g. 13kg Gas Cylinder)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sizeKg,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Size (kg)'),
                validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a valid number' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Purchase Price (KES)'),
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _refillPrice,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Refill Price (KES)'),
                      validator: (v) => (double.tryParse(v ?? '') == null) ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                validator: (v) => (int.tryParse(v ?? '') == null) ? 'Enter a whole number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active (visible to customers)'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),
              LoadingButton(label: isEdit ? 'Save Changes' : 'Add Cylinder', loading: _saving, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
