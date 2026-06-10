import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/category_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class CategoryService {
  final AuthService authService;

  CategoryService(this.authService);

  Future<List<CategoryModel>> getCategories() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Kategoriler alınamadı');
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } on TimeoutException {
      throw Exception('Kategori servisi zaman aşımına uğradı');
    }
  }

  Future<String?> createCategory({
    required String name,
    String? description,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories');
      final response = await http
          .post(
            uri,
            headers: authService.authHeaders,
            body: jsonEncode({'name': name, 'description': description}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Kategori eklenemedi';
      }
      return null;
    } on TimeoutException {
      return 'Sunucu zaman aşımına uğradı';
    }
  }

  Future<String?> updateCategory({
    required int id,
    required String name,
    String? description,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/$id');
      final response = await http
          .put(
            uri,
            headers: authService.authHeaders,
            body: jsonEncode({'name': name, 'description': description}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Kategori güncellenemedi';
      }
      return null;
    } on TimeoutException {
      return 'Sunucu zaman aşımına uğradı';
    }
  }

  Future<String?> deleteCategory(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/categories/$id');
      final response = await http
          .delete(uri, headers: authService.authHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Kategori silinemedi';
      }
      return null;
    } on TimeoutException {
      return 'Sunucu zaman aşımına uğradı';
    }
  }
}
