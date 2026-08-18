class Payment {
  final String id;
  final String orderNumber;
  final double amount;
  final String method; // mpesa | card
  final String status; // pending | successful | failed | cancelled
  final String? transactionReference;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.orderNumber,
    required this.amount,
    required this.method,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0,
      method: json['method'] ?? '',
      status: json['status'] ?? 'pending',
      transactionReference: json['transaction_reference'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
