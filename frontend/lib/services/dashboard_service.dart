import 'api_client.dart';

class DashboardService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fetchSummary() async {
    final data = await _api.get('dashboard/summary/');
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> fetchStaffActivity() async {
    final data = await _api.get('dashboard/staff-activity/');
    return List<dynamic>.from(data);
  }
}
