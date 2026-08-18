import '../models/payment.dart';
import 'api_client.dart';

class PaymentService {
  final ApiClient _api = ApiClient();

  Future<List<Payment>> fetchPayments() async {
    final data = await _api.get('payments/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => Payment.fromJson(e)).toList();
  }

  /// Triggers an M-Pesa STK push. The customer will get a prompt on their
  /// phone to enter their M-Pesa PIN. Poll fetchPayments() or listen for a
  /// push notification to know when it completes.
  Future<Map<String, dynamic>> initiateMpesaPayment({
    required String orderId,
    required String phoneNumber,
  }) async {
    final data = await _api.post('payments/mpesa/initiate/', body: {
      'order': orderId,
      'phone_number': phoneNumber,
    });
    return data;
  }

  /// Card payments should use a real gateway SDK client-side (Stripe, Flutterwave,
  /// Paystack) to tokenize the card, then pass the resulting token here.
  Future<Map<String, dynamic>> initiateCardPayment({
    required String orderId,
    required String paymentToken,
  }) async {
    final data = await _api.post('payments/card/initiate/', body: {
      'order': orderId,
      'payment_token': paymentToken,
    });
    return data;
  }
}
