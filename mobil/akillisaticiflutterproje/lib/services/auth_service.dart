import '../core/constants/api_constants.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      ApiConstants.login,
      body: {'email': email, 'password': password},
    );
    return _extractToken(data);
  }

  Future<void> register({
    required String fullName,
    required String storeName,
    required String email,
    required String password,
  }) async {
    await _client.post(
      ApiConstants.register,
      body: {
        'fullName': fullName,
        'storeName': storeName,
        'email': email,
        'password': password,
      },
    );
  }

  Future<dynamic> requestPasswordReset({required String email}) async {
    return _client.post(ApiConstants.forgotPassword, body: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      ApiConstants.resetPassword,
      body: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  String? _extractToken(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['token'] is String) return data['token'] as String;
      if (data['accessToken'] is String) return data['accessToken'] as String;
      if (data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        if (inner['token'] is String) return inner['token'] as String;
        if (inner['accessToken'] is String) {
          return inner['accessToken'] as String;
        }
      }
    }
    return null;
  }
}
