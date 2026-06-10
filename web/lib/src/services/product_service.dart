import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/product_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class ProductService {
  final AuthService authService;

  ProductService(this.authService);

  Future<List<ProductModel>> getPublishedProducts({String? category}) async {
    try {
      final query = <String, String>{
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/products/public',
      ).replace(queryParameters: query.isEmpty ? null : query);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Ürünler alınamadı');
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .whereType<Map<String, dynamic>>()
          .map(_normalizeProductJson)
          .map(ProductModel.fromJson)
          .toList();
    } on TimeoutException {
      throw Exception('Ürün servisi zaman aşımına uğradı');
    }
  }

  Future<ProductModel> getPublishedProductDetail(int id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/public/$id');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Ürün detayı alınamadı');
      }

      return ProductModel.fromJson(
        _normalizeProductJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        ),
      );
    } on TimeoutException {
      throw Exception('Ürün detay servisi zaman aşımına uğradı');
    }
  }

  Future<List<ProductModel>> getMyProducts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products');
    final response = await http
        .get(uri, headers: authService.authHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 401) {
      throw Exception('Oturum süresi doldu');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ürünlerim alınamadı');
    }

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .whereType<Map<String, dynamic>>()
        .map(_normalizeProductJson)
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<List<ProductModel>> getAdminProducts() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/admin/all');
    final response = await http
        .get(uri, headers: authService.authHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 403) {
      throw Exception('Bu işlem için admin yetkisi gerekli');
    }
    if (response.statusCode == 401) {
      throw Exception('Oturum süresi doldu');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Admin ürünleri alınamadı');
    }

    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .whereType<Map<String, dynamic>>()
        .map(_normalizeProductJson)
        .map(ProductModel.fromJson)
        .toList();
  }

  Future<String?> createProduct({
    required String title,
    required String? description,
    required double? minPrice,
    required double? maxPrice,
    required String? category,
    required String? imageUrl,
    required String status,
    int stockQuantity = 0,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products');
    final request =
        http.MultipartRequest('POST', uri)
          ..headers.addAll(_authMultipartHeaders)
          ..fields['title'] = title
          ..fields['description'] = description ?? ''
          ..fields['category'] = category ?? ''
          ..fields['imageUrl'] = _normalizeImageUrl(imageUrl) ?? ''
          ..fields['isAiGenerated'] = 'false'
          ..fields['status'] = status
          ..fields['stockQuantity'] = stockQuantity.toString();

    if (minPrice != null) request.fields['minPrice'] = minPrice.toString();
    if (maxPrice != null) request.fields['maxPrice'] = maxPrice.toString();

    final streamed = await request.send().timeout(ApiConfig.requestTimeout);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      return 'Ürün eklenemedi';
    }
    return null;
  }

  Future<String?> createSmartProduct({
    required String title,
    required String? category,
    required String? petType,
    required String? highlights,
    required String? generatedDescription,
    required double? minPrice,
    required double? maxPrice,
    required String? imageUrl,
    required String status,
    int stockQuantity = 0,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/admin/smart');
    final response = await http
        .post(
          uri,
          headers: authService.authHeaders,
          body: jsonEncode({
            'title': title,
            'category': category,
            'petType': petType,
            'highlights': highlights,
            'generatedDescription': generatedDescription,
            'minPrice': minPrice,
            'maxPrice': maxPrice,
            'imageUrl': _normalizeImageUrl(imageUrl),
            'status': status,
            'stockQuantity': stockQuantity,
          }),
        )
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode == 403) {
      return 'Bu işlem için admin yetkisi gerekli';
    }
    if (response.statusCode == 401) {
      return 'Oturum süresi doldu';
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'Akıllı ürün eklenemedi';
    }

    return null;
  }

  Future<Map<String, dynamic>> getAiSuggestion({
    required String title,
    String? category,
    String? size,
    String? imageUrl,
    String? imageBase64,
    String? imageMimeType,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/ai/suggest');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'title': title,
              'category': category,
              'size': size,
              'imageUrl': imageUrl,
              'imageBase64': imageBase64,
              'imageMimeType': imageMimeType,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('AI önerisi alınamadı: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('AI yanıt formatı geçersiz');
    } on TimeoutException {
      throw Exception('AI servisi zaman aşımına uğradı');
    }
  }

  Future<Map<String, dynamic>> getScrapedPriceSuggestion({
    required String query,
    String? category,
    String? weight,
    String? brand,
    int maxPages = 2,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/ai/price-scrape');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'query': query.trim(),
              'maxPages': maxPages,
              if (weight != null && weight.isNotEmpty) 'weight': weight,
              if (brand != null && brand.isNotEmpty) 'brand': brand,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Fiyat scrape sonucu alınamadı');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('Scrape yanıt formatı geçersiz');
    } on TimeoutException {
      throw Exception('Fiyat analizi servisi zaman aşımına uğradı');
    }
  }

  Future<String?> updateProduct({
    required int id,
    required String title,
    required String? description,
    required double? minPrice,
    required double? maxPrice,
    required String? category,
    required String? imageUrl,
    required String status,
    int stockQuantity = 0,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/$id');
    final request =
        http.MultipartRequest('PUT', uri)
          ..headers.addAll(_authMultipartHeaders)
          ..fields['title'] = title
          ..fields['description'] = description ?? ''
          ..fields['category'] = category ?? ''
          ..fields['imageUrl'] = _normalizeImageUrl(imageUrl) ?? ''
          ..fields['isAiGenerated'] = 'false'
          ..fields['status'] = status
          ..fields['stockQuantity'] = stockQuantity.toString();

    if (minPrice != null) request.fields['minPrice'] = minPrice.toString();
    if (maxPrice != null) request.fields['maxPrice'] = maxPrice.toString();

    final streamed = await request.send().timeout(ApiConfig.requestTimeout);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      return 'Ürün güncellenemedi';
    }
    return null;
  }

  Future<String?> deleteProduct(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/$id');
    final response = await http
        .delete(uri, headers: authService.authHeaders)
        .timeout(ApiConfig.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'Ürün silinemedi';
    }
    return null;
  }

  /// Resmi backend'e yükler ve sunucu URL'ini döner. Hata olursa exception fırlatır.
  Future<String> uploadImage({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/products/admin/upload-image',
      );

      final request =
          http.MultipartRequest('POST', uri)
            ..headers.addAll(_authMultipartHeaders)
            ..files.add(
              http.MultipartFile.fromBytes('file', bytes, filename: fileName),
            );

      final streamed = await request.send().timeout(ApiConfig.requestTimeout);
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw Exception('Resim yüklenemedi: ${streamed.statusCode}');
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final relativePath = json['url'] as String;
      return '${ApiConfig.normalizedBaseUrl}$relativePath';
    } on TimeoutException {
      throw Exception('Resim yükleme zaman aşımına uğradı');
    }
  }

  Map<String, String> get _authMultipartHeaders {
    final token = authService.token;
    if (token == null || token.isEmpty) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _normalizeProductJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);
    normalized['imageUrl'] = _normalizeImageUrl(json['imageUrl'] as String?);
    return normalized;
  }

  String? _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null) return null;

    final url = rawUrl.trim();
    if (url.isEmpty) return null;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final normalizedPath = url.startsWith('/') ? url : '/$url';
    return '${ApiConfig.normalizedBaseUrl}$normalizedPath';
  }
}
