import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;
  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => message;
}

/// Thin wrapper around http that:
/// - prefixes requests with the configured API base URL
/// - attaches the JWT access token to every request
/// - transparently refreshes the access token once on a 401 and retries
/// - throws ApiException with a readable message on non-2xx responses
class ApiClient {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';

  Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await TokenStorage.getAccessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$cleanPath').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _send(() => http.get(_uri(path, query), headers: null), path, query: query, method: 'GET');
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool withAuth = true}) async {
    return _send(
      () async => http.post(_uri(path), headers: await _headers(withAuth: withAuth), body: jsonEncode(body ?? {})),
      path,
      body: body,
      method: 'POST',
      withAuth: withAuth,
    );
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    return _send(
      () async => http.patch(_uri(path), headers: await _headers(), body: jsonEncode(body ?? {})),
      path,
      body: body,
      method: 'PATCH',
    );
  }

  Future<dynamic> delete(String path) async {
    return _send(
      () async => http.delete(_uri(path), headers: await _headers()),
      path,
      method: 'DELETE',
    );
  }

  /// Generic request executor with a single automatic retry after refreshing
  /// the access token if the server responds 401 Unauthorized.
  Future<dynamic> _send(
    Future<http.Response> Function() requestFn,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    required String method,
    bool withAuth = true,
    bool isRetry = false,
  }) async {
    http.Response response;

    // GET requests build their own headers with auth since they don't go
    // through the closures above uniformly -- handle explicitly.
    if (method == 'GET') {
      final headers = await _headers(withAuth: withAuth);
      response = await http.get(_uri(path, query), headers: headers);
    } else {
      response = await requestFn();
    }

    if (response.statusCode == 401 && withAuth && !isRetry) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        return _send(requestFn, path, query: query, body: body, method: method, withAuth: withAuth, isRetry: true);
      }
    }

    return _parse(response);
  }

  dynamic _parse(http.Response response) {
    final isJson = response.headers['content-type']?.contains('application/json') ?? false;
    final decoded = isJson && response.body.isNotEmpty ? jsonDecode(response.body) : response.body;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed (${response.statusCode})';
    if (decoded is Map && decoded.isNotEmpty) {
      message = decoded.values.first is List ? decoded.values.first.first.toString() : decoded.values.first.toString();
      if (decoded.containsKey('detail')) message = decoded['detail'].toString();
    }
    throw ApiException(response.statusCode, message, decoded);
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await TokenStorage.getRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await http.post(
        _uri('accounts/login/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await TokenStorage.saveAccessToken(data['access']);
        return true;
      }
    } catch (_) {
      // fall through to false
    }
    return false;
  }
}
