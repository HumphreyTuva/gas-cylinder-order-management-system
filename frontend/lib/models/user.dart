class AppUser {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? email;
  final String phoneNumber;
  final String role; // customer | staff | management
  final String? defaultDeliveryAddress;

  AppUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.defaultDeliveryAddress,
  });

  bool get isCustomer => role == 'customer';
  bool get isStaff => role == 'staff';
  bool get isManagement => role == 'management';

  String get fullName =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').isEmpty
          ? username
          : [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'] ?? 'customer',
      defaultDeliveryAddress: json['default_delivery_address'],
    );
  }
}
