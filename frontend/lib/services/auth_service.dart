import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<AppUser> login(String username, String password) async {
    final data = await _api.post(
      'accounts/login/',
      body: {'username': username, 'password': password},
      withAuth: false,
    );
    await TokenStorage.saveTokens(access: data['access'], refresh: data['refresh']);
    return AppUser.fromJson(data['user']);
  }

  Future<AppUser> registerCustomer({
    required String username,
    required String password,
    required String passwordConfirm,
    required String phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? defaultDeliveryAddress,
  }) async {
    await _api.post(
      'accounts/register/',
      body: {
        'username': username,
        'password': password,
        'password_confirm': passwordConfirm,
        'phone_number': phoneNumber,
        'email': email,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'default_delivery_address': defaultDeliveryAddress,
      },
      withAuth: false,
    );
    // Registration succeeded -- log the new customer in immediately.
    return login(username, password);
  }

  Future<AppUser> fetchMe() async {
    final data = await _api.get('accounts/me/');
    return AppUser.fromJson(data);
  }

  Future<void> registerFcmToken(String token) async {
    await _api.post('accounts/fcm-token/', body: {'fcm_token': token});
  }

  Future<void> logout() => TokenStorage.clear();
}
