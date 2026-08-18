import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _api = ApiClient();

  Future<List<GasOrder>> fetchOrders({String? statusFilter}) async {
    final data = await _api.get('orders/', query: statusFilter != null ? {'status': statusFilter} : null);
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => GasOrder.fromJson(e)).toList();
  }

  Future<GasOrder> fetchOrder(String id) async {
    final data = await _api.get('orders/$id/');
    return GasOrder.fromJson(data);
  }

  Future<GasOrder> placeOrder({
    required String orderType,
    required String cylinderTypeId,
    required int quantity,
    required String deliveryAddress,
    required String deliveryPhoneNumber,
    String? deliveryNotes,
  }) async {
    final data = await _api.post('orders/', body: {
      'order_type': orderType,
      'cylinder_type': cylinderTypeId,
      'quantity': quantity,
      'delivery_address': deliveryAddress,
      'delivery_phone_number': deliveryPhoneNumber,
      'delivery_notes': deliveryNotes,
    });
    return GasOrder.fromJson(data);
  }

  Future<GasOrder> cancelOrder(String id) async {
    final data = await _api.post('orders/$id/cancel/');
    return GasOrder.fromJson(data);
  }

  /// Staff/management only.
  Future<GasOrder> updateStatus(String id, String status, {String? note}) async {
    final data = await _api.post('orders/$id/update_status/', body: {'status': status, 'note': note ?? ''});
    return GasOrder.fromJson(data);
  }

  Future<GasOrder> assignToMe(String id) async {
    final data = await _api.post('orders/$id/assign_to_me/');
    return GasOrder.fromJson(data);
  }
}
