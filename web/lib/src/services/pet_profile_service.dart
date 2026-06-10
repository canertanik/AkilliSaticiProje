import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_profile_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class PetProfileService {
  final AuthService authService;

  PetProfileService(this.authService);

  Future<List<PetProfileModel>> getMyPets() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/petprofiles');
    final response = await http
        .get(uri, headers: authService.authHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Oturum süresi doldu. Lütfen tekrar giriş yapın.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Evcil hayvan profilleri alınamadı');
    }

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .whereType<Map<String, dynamic>>()
        .map(PetProfileModel.fromJson)
        .toList();
  }

  Future<PetProfileModel> createPet(Map<String, dynamic> data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/petprofiles');
    final response = await http
        .post(uri, headers: authService.authHeaders, body: jsonEncode(data))
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Evcil hayvan eklenemedi');
    }

    return PetProfileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PetProfileModel> updatePet(int id, Map<String, dynamic> data) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/petprofiles/$id');
    final response = await http
        .put(uri, headers: authService.authHeaders, body: jsonEncode(data))
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Evcil hayvan güncellenemedi');
    }

    return PetProfileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deletePet(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/petprofiles/$id');
    final response = await http
        .delete(uri, headers: authService.authHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Evcil hayvan silinemedi');
    }
  }
}
