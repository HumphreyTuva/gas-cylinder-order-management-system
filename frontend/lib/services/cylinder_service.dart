import '../models/cylinder.dart';
import 'api_client.dart';

class CylinderService {
  final ApiClient _api = ApiClient();

  Future<List<CylinderType>> fetchCatalogue() async {
    final data = await _api.get('cylinders/types/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => CylinderType.fromJson(e)).toList();
  }

  /// Staff/management only.
  Future<CylinderType> createCylinderType({
    required String name,
    required double sizeKg,
    required double purchasePrice,
    required double refillPrice,
    required int stockQuantity,
    String description = '',
    bool isActive = true,
  }) async {
    final data = await _api.post('cylinders/types/', body: {
      'name': name,
      'size_kg': sizeKg,
      'purchase_price': purchasePrice,
      'refill_price': refillPrice,
      'stock_quantity': stockQuantity,
      'description': description,
      'is_active': isActive,
    });
    return CylinderType.fromJson(data);
  }

  /// Staff/management only.
  Future<CylinderType> updateCylinderType(
    String id, {
    required String name,
    required double sizeKg,
    required double purchasePrice,
    required double refillPrice,
    required int stockQuantity,
    String description = '',
    bool isActive = true,
  }) async {
    final data = await _api.patch('cylinders/types/$id/', body: {
      'name': name,
      'size_kg': sizeKg,
      'purchase_price': purchasePrice,
      'refill_price': refillPrice,
      'stock_quantity': stockQuantity,
      'description': description,
      'is_active': isActive,
    });
    return CylinderType.fromJson(data);
  }

  /// Staff/management only.
  Future<void> deleteCylinderType(String id) async {
    await _api.delete('cylinders/types/$id/');
  }
}
