import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class BackendAuthService {
  static const String defaultApiBaseUrl =
      String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://herbb-production.up.railway.app',
      );
  static const String _legacyApiBaseUrl =
      'https://herbal-trace-production.up.railway.app';
  static const String _defaultUsername = 'admin';
  static const String _defaultPassword = 'admin123';

  static const String _tokenKey = 'backendAuthToken';
  static const String _refreshTokenKey = 'backendRefreshToken';
  static const String _usernameKey = 'backendUsername';
  static const String _passwordKey = 'backendPassword';
  static const Duration _requestTimeout = Duration(seconds: 20);

  static String get apiBaseUrl {
    final configured =
        StorageService.getSetting('apiBaseUrl', defaultValue: defaultApiBaseUrl);

    if (configured is String && configured.trim().isNotEmpty) {
      if (configured == _legacyApiBaseUrl) {
        return defaultApiBaseUrl;
      }
      return configured;
    }

    return defaultApiBaseUrl;
  }

  static Future<String> getValidToken() async {
    final existingToken =
        StorageService.getSetting(_tokenKey) ?? StorageService.getUserData(_tokenKey);

    if (_isTokenUsable(existingToken)) {
      return existingToken as String;
    }

    final refreshToken = StorageService.getSetting(_refreshTokenKey);
    if (refreshToken is String && refreshToken.isNotEmpty) {
      final refreshed = await _refreshAccessToken(refreshToken);
      if (refreshed != null && _isTokenUsable(refreshed)) {
        await StorageService.saveSetting(_tokenKey, refreshed);
        await StorageService.saveUserData(_tokenKey, refreshed);
        return refreshed;
      }
    }

    return _loginAndFetchToken();
  }

  static Future<String> _loginAndFetchToken() async {
    final username =
        (StorageService.getSetting(_usernameKey) as String?) ?? _defaultUsername;
    final password =
        (StorageService.getSetting(_passwordKey) as String?) ?? _defaultPassword;

    final response = await _postWithRetry(
      Uri.parse('$apiBaseUrl/api/v1/auth/login'),
      {'username': username, 'password': password},
    );

    if (response.statusCode != 200) {
      throw Exception('Backend login failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>?;
    final token = data?['token']?.toString();
    final refreshToken = data?['refreshToken']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Backend login succeeded but token missing');
    }

    await StorageService.saveSetting(_tokenKey, token);
    await StorageService.saveUserData(_tokenKey, token);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await StorageService.saveSetting(_refreshTokenKey, refreshToken);
    }

    return token;
  }

  static Future<String?> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await _postWithRetry(
        Uri.parse('$apiBaseUrl/api/v1/auth/refresh'),
        {'refreshToken': refreshToken},
      );

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      return data?['token']?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> _postWithRetry(
    Uri uri,
    Map<String, dynamic> body,
  ) async {
    const attempts = 3;
    Object? lastError;

    for (var i = 0; i < attempts; i++) {
      try {
        return await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } on http.ClientException catch (e) {
        lastError = e;
      }

      if (i < attempts - 1) {
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }

    throw Exception('Unable to reach backend auth service at $uri. ${lastError ?? 'Unknown network error'}');
  }

  static bool _isTokenUsable(dynamic token) {
    if (token is! String || token.isEmpty) return false;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payloadBase64 = base64Url.normalize(parts[1]);
      final payloadJson =
          utf8.decode(base64Url.decode(payloadBase64), allowMalformed: true);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      final exp = payload['exp'];
      if (exp is! int) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expiry.isAfter(DateTime.now().add(const Duration(seconds: 30)));
    } catch (_) {
      return false;
    }
  }
}
