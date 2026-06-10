import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'api_config.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';

  String? _token;
  AppUser? _currentUser;
  bool _isLoading = false;

  AuthService() {
    _restoreSession();
  }

  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  AppUser? get currentUser => _currentUser;
  String? get token => _token;

  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null || savedToken.isEmpty) return;

    _token = savedToken;
    await fetchCurrentUser();
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = _tryParseObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return (body['message'] ?? 'Giriş başarısız').toString();
      }

      _token = (body['token'] ?? '').toString();
      if (_token == null || _token!.isEmpty) {
        return 'Token alınamadı';
      }

      final userJson = body['user'];
      if (userJson is Map<String, dynamic>) {
        _currentUser = AppUser.fromJson(userJson);
      } else {
        await fetchCurrentUser();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, _token!);

      return null;
    } on TimeoutException {
      return 'Sunucu zaman aşımına uğradı';
    } catch (_) {
      return 'Sunucuya bağlanılamadı';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> register({
    required String fullName,
    required String storeName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/register');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': fullName,
              'storeName': storeName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = _tryParseObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return (body['message'] ?? 'Kayıt başarısız').toString();
      }

      return null;
    } on TimeoutException {
      return 'Sunucu zaman aşımına uğradı';
    } catch (_) {
      return 'Sunucuya bağlanılamadı';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentUser() async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/me');
      final response = await http
          .get(uri, headers: authHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = _tryParseObject(response.body);
        _currentUser = AppUser.fromJson(json);
      } else {
        await logout();
      }
    } catch (_) {
      await logout();
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  Map<String, dynamic> _tryParseObject(String responseBody) {
    if (responseBody.trim().isEmpty) return {};
    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) return decoded;
    return {};
  }
}
