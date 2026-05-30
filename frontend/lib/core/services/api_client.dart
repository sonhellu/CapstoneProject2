import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Centralized HTTP client that automatically attaches the Firebase ID Token
/// to every request as `Authorization: Bearer <token>`.
///
/// Usage:
/// ```dart
/// final api = ApiClient();
/// final res = await api.get('/users/me');
/// final res = await api.post('/posts', body: {'title': 'Hello'});
/// ```
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ── Base URL ───────────────────────────────────────────────────────────────
  static const String baseUrl = 'https://capstoneproject2-production-f16d.up.railway.app';

  static const _kTimeout = Duration(seconds: 10);

  final http.Client _client;

  // ── Public methods ─────────────────────────────────────────────────────────

  Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _uri(path, queryParams);
    final headers = await _authHeaders();
    return _client.get(uri, headers: headers).timeout(_kTimeout);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final headers = await _authHeaders();
    return _client
        .post(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(_kTimeout);
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final headers = await _authHeaders();
    return _client
        .put(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(_kTimeout);
  }

  Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path);
    final headers = await _authHeaders();
    return _client
        .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
        .timeout(_kTimeout);
  }

  Future<http.Response> delete(String path) async {
    final uri = _uri(path);
    final headers = await _authHeaders();
    return _client.delete(uri, headers: headers).timeout(_kTimeout);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters: queryParams,
    );
  }

  /// Returns headers with a fresh Firebase ID Token.
  /// [getIdToken()] automatically refreshes the token if it has expired.
  Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    return {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }
}
