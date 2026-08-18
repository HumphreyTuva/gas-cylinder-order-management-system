import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/payment_service.dart';
import '../../widgets/loading_button.dart';

class PaymentScreen extends StatefulWidget {
  final GasOrder order;
  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _paymentService = PaymentService();
  String _method = 'mpesa';
  final _phoneController = TextEditingController();
  bool _submitting = false;

  Future<void> _pay() async {
    setState(() => _submitting = true);
    try {
      if (_method == 'mpesa') {
        if (_phoneController.text.trim().isEmpty) {
          throw Exception('Please enter the M-Pesa phone number to receive the payment prompt.');
        }
        await _paymentService.initiateMpesaPayment(
          orderId: widget.order.id,
          phoneNumber: _phoneController.text.trim(),
        );
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Check Your Phone'),
              content: const Text(
                'An M-Pesa payment prompt has been sent. Please enter your M-Pesa PIN on your phone to complete the payment.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // In production, integrate the card gateway's SDK here to securely
        // tokenize the card, then send only the resulting token.
        await _paymentService.initiateCardPayment(
          orderId: widget.order.id,
          paymentToken: 'demo-token-from-card-gateway-sdk',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card payment initiated. You will be notified once confirmed.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay for Order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: const Color(0x0D1B6F5C),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order ${widget.order.orderNumber}'),
                      Text('KES ${widget.order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Select Payment Method', style: Theme.of(context).textTheme.titleMedium),
              RadioListTile<String>(
                value: 'mpesa',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = v!),
                title: const Text('M-Pesa'),
                subtitle: const Text('Pay via STK push to your phone'),
                secondary: const Icon(Icons.phone_android),
              ),
              RadioListTile<String>(
                value: 'card',
                groupValue: _method,
                onChanged: (v) => setState(() => _method = v!),
                title: const Text('Debit/Credit Card'),
                secondary: const Icon(Icons.credit_card),
              ),
              const SizedBox(height: 12),
              if (_method == 'mpesa')
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Phone Number',
                    hintText: '2547XXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
              if (_method == 'card')
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'You will be redirected to a secure card payment form.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 24),
              LoadingButton(
                label: _method == 'mpesa' ? 'Send M-Pesa Prompt' : 'Pay with Card',
                loading: _submitting,
                onPressed: _pay,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
