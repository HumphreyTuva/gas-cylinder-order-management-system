import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _api = ApiClient();

  Future<List<AppNotification>> fetchNotifications() async {
    final data = await _api.get('notifications/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markRead(String id) => _api.post('notifications/$id/mark_read/');
  Future<void> markAllRead() => _api.post('notifications/mark_all_read/');
}
