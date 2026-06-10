import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/store_settings_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class SettingsService {
  final AuthService authService;

  SettingsService(this.authService);

  Future<StoreSettingsModel> getSettings() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/settings');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return StoreSettingsModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Ayarlar alınamadı');
    } catch (_) {
      // Return empty settings on error
      return const StoreSettingsModel(
        popularCategories: [],
        popularBrands: [],
      );
    }
  }

  Future<String?> updateSettings(StoreSettingsModel settings) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/settings');
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${authService.token}',
            },
            body: jsonEncode(settings.toJson()),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        return 'Bu işlem için admin yetkisi gerekli';
      }
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Ayarlar kaydedilemedi';
      }

      return null;
    } catch (e) {
      return 'Sunucuya bağlanılamadı: $e';
    }
  }
}
