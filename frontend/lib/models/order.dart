class OrderStatusEvent {
  final String status;
  final String? changedByUsername;
  final String? note;
  final DateTime changedAt;

  OrderStatusEvent({
    required this.status,
    required this.changedByUsername,
    required this.note,
    required this.changedAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: json['status'],
      changedByUsername: json['changed_by_username'],
      note: json['note'],
      changedAt: DateTime.parse(json['changed_at']),
    );
  }
}

class GasOrder {
  final String id;
  final String orderNumber;
  final String customerUsername;
  final String orderType; // purchase | refill
  final String cylinderTypeId;
  final String cylinderTypeName;
  final int quantity;
  final String status;
  final String deliveryAddress;
  final String deliveryPhoneNumber;
  final String? deliveryNotes;
  final double totalAmount;
  final bool isPaid;
  final List<OrderStatusEvent> statusHistory;
  final DateTime createdAt;

  GasOrder({
    required this.id,
    required this.orderNumber,
    required this.customerUsername,
    required this.orderType,
    required this.cylinderTypeId,
    required this.cylinderTypeName,
    required this.quantity,
    required this.status,
    required this.deliveryAddress,
    required this.deliveryPhoneNumber,
    required this.deliveryNotes,
    required this.totalAmount,
    required this.isPaid,
    required this.statusHistory,
    required this.createdAt,
  });

  static const List<String> statusFlow = [
    'pending',
    'confirmed',
    'processing',
    'out_for_delivery',
    'delivered',
  ];

  factory GasOrder.fromJson(Map<String, dynamic> json) {
    return GasOrder(
      id: json['id'].toString(),
      orderNumber: json['order_number'] ?? '',
      customerUsername: json['customer_username'] ?? '',
      orderType: json['order_type'] ?? 'purchase',
      cylinderTypeId: json['cylinder_type'].toString(),
      cylinderTypeName: json['cylinder_type_detail']?['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: json['status'] ?? 'pending',
      deliveryAddress: json['delivery_address'] ?? '',
      deliveryPhoneNumber: json['delivery_phone_number'] ?? '',
      deliveryNotes: json['delivery_notes'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0,
      isPaid: json['is_paid'] ?? false,
      statusHistory: (json['status_history'] as List? ?? [])
          .map((e) => OrderStatusEvent.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
