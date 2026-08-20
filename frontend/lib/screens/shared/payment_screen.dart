import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../models/payment.dart';
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
  bool _waitingForConfirmation = false;
  String? _paymentId;

  Future<void> _pay() async {
    setState(() => _submitting = true);
    try {
      if (_method == 'mpesa') {
        if (_phoneController.text.trim().isEmpty) {
          throw Exception('Please enter the M-Pesa phone number to receive the payment prompt.');
        }
        final result = await _paymentService.initiateMpesaPayment(
          orderId: widget.order.id,
          phoneNumber: _phoneController.text.trim(),
        );
        _paymentId = result['payment']?['id']?.toString();
        if (mounted) setState(() => _waitingForConfirmation = true);
        if (_paymentId != null) {
          _pollForResult(_paymentId!);
        }
      } else {
        final result = await _paymentService.initiateCardPayment(
          orderId: widget.order.id,
          paymentToken: 'demo-token-from-card-gateway-sdk',
        );
        _paymentId = result['payment']?['id']?.toString();
        if (mounted) setState(() => _waitingForConfirmation = true);
        if (_paymentId != null) {
          _pollForResult(_paymentId!);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pollForResult(String paymentId) async {
    const maxAttempts = 20;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      try {
        final payment = await _paymentService.fetchPayment(paymentId);
        if (payment.status != 'pending') {
          if (mounted) _showResult(payment);
          return;
        }
      } catch (_) {
        // Transient network hiccup while polling -- try again next tick.
      }
    }
    if (mounted) {
      setState(() => _waitingForConfirmation = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Still Processing'),
          content: const Text(
            "We haven't received confirmation yet. This can take a little longer -- "
            'check your Orders or Notifications shortly to see if it went through.',
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
  }

  void _showResult(Payment payment) {
    setState(() => _waitingForConfirmation = false);
    final success = payment.status == 'successful';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle : Icons.error_outline,
          color: success ? Colors.green : Colors.red,
          size: 40,
        ),
        title: Text(success ? 'Payment Successful' : 'Payment Failed'),
        content: Text(
          success
              ? 'KES ${payment.amount.toStringAsFixed(0)} received for order ${widget.order.orderNumber}.'
              : payment.status == 'cancelled'
                  ? 'The payment was cancelled.'
                  : 'The payment could not be completed. You can try again from the order.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay for Order')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _waitingForConfirmation
              ? _buildWaitingState()
              : SingleChildScrollView(
                  child: _buildFormState(),
                ),
        ),
      ),
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _method == 'mpesa'
                ? 'Waiting for M-Pesa confirmation...\nAsk the customer to enter their PIN on their phone.'
                : 'Confirming card payment...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
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
              hintText: 'e.g. 0712345678, 254712345678, or +254712345678',
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
    );
  }
}
