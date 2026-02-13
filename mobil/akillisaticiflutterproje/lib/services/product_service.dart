import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../core/utils/platform_file.dart';
import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  final ApiClient _client;

  ProductService(this._client);

  Future<List<Product>> fetchProducts() async {
    final data = await _client.get(ApiConstants.products);
    final list = _extractList(data);
    return list.map((e) => _normalizeProduct(Product.fromJson(e))).toList();
  }

  Future<Product> createProduct(Product product) async {
    final data = await _sendMultipart('POST', ApiConstants.products, product);
    final map = _extractMap(data);
    return _normalizeProduct(Product.fromJson(map));
  }

  Future<Product> updateProduct(Product product) async {
    final path = '${ApiConstants.products}/${product.id}';
    final data = await _sendMultipart('PUT', path, product);
    final map = _extractMap(data);
    return _normalizeProduct(Product.fromJson(map));
  }

  Future<dynamic> _sendMultipart(
    String method,
    String path,
    Product product,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final request = http.MultipartRequest(method, uri);
    request.headers.addAll(_client.authHeaders);

    final payload = product.toJson();
    final isLocalPath = _isLocalFilePath(product.imageUrl.trim());
    if (isLocalPath) {
      payload.remove('imageUrl');
    }
    payload.forEach((key, value) {
      if (value == null) return;
      request.fields[key] = value.toString();
    });

    if (kIsWeb && product.webImageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          product.webImageBytes!,
          filename: 'upload.jpg',
        ),
      );
    }
    if (!kIsWeb && isLocalPath) {
      final file = await buildMultipartFileFromPath(product.imageUrl);
      if (file != null) {
        request.files.add(file);
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Request failed',
        body: response.body,
      );
    }

    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  Product _normalizeProduct(Product product) {
    final url = product.imageUrl.trim();
    if (url.isEmpty) return product;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return product;
    }
    if (_isLocalFilePath(url)) {
      return product;
    }
    final base =
        ApiConstants.baseUrl.endsWith('/')
            ? ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 1)
            : ApiConstants.baseUrl;
    final normalized = url.startsWith('/') ? '$base$url' : '$base/$url';
    return product.copyWith(imageUrl: normalized);
  }

  bool _isLocalFilePath(String url) {
    if (url.startsWith('file://')) return true;
    if (url.startsWith('content://')) return true;
    if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(url)) return true;
    if (url.startsWith('/storage/') || url.startsWith('/data/')) return true;
    return false;
  }

  Future<void> deleteProduct(String id) async {
    await _client.delete('${ApiConstants.products}/$id');
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    return <String, dynamic>{};
  }
}
