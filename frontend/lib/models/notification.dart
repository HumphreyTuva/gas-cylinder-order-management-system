class AppNotification {
  final String id;
  final String notificationType;
  final String title;
  final String message;
  final String? relatedOrder;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.notificationType,
    required this.title,
    required this.message,
    required this.relatedOrder,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      notificationType: json['notification_type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedOrder: json['related_order']?.toString(),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
