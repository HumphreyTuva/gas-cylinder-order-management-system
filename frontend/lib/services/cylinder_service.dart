import '../models/cylinder.dart';
import 'api_client.dart';

class CylinderService {
  final ApiClient _api = ApiClient();

  Future<List<CylinderType>> fetchCatalogue() async {
    final data = await _api.get('cylinders/types/');
    final results = data is Map && data.containsKey('results') ? data['results'] : data;
    return (results as List).map((e) => CylinderType.fromJson(e)).toList();
  }
}
