import '../models/user.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _api = ApiClient();

  /// Management only. Lists staff and management accounts.
  Future<List<AppUser>> fetchStaff() async {
    final data = await _api.get('accounts/staff/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => AppUser.fromJson(e)).toList();
  }

  /// Management only. Creates a new staff or management account.
  Future<AppUser> createStaff({
    required String username,
    required String password,
    required String phoneNumber,
    required String role, // 'staff' or 'management'
    String firstName = '',
    String lastName = '',
    String? email,
  }) async {
    final data = await _api.post('accounts/staff/', body: {
      'username': username,
      'password': password,
      'phone_number': phoneNumber,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
    });
    return AppUser.fromJson(data);
  }

  Future<List<AppUser>> fetchCustomers() async {
    final data = await _api.get('accounts/customers/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => AppUser.fromJson(e)).toList();
  }

  /// Management only. Deactivates (soft-deletes) a staff/management account.
  Future<void> deactivateStaff(String id) async {
    await _api.delete('accounts/staff/$id/');
  }
}
