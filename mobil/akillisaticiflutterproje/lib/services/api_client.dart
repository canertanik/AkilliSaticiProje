import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  ApiException({required this.statusCode, required this.message, this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  final Map<String, String> _defaultHeaders;
  String? _authToken;

  ApiClient({
    required this.baseUrl,
    http.Client? client,
    Map<String, String>? defaultHeaders,
  }) : _client = client ?? http.Client(),
       _defaultHeaders =
           defaultHeaders ??
           const {
             'Content-Type': 'application/json',
             'Accept': 'application/json',
           };

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> get authHeaders {
    if (_authToken == null || _authToken!.isEmpty) return <String, String>{};
    return <String, String>{'Authorization': 'Bearer $_authToken'};
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      'GET',
      path,
      headers: headers,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      'POST',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      'PUT',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request(
      'DELETE',
      path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, '$v')),
    );

    final mergedHeaders = <String, String>{
      ..._defaultHeaders,
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      ...?headers,
    };

    http.Response response;
    final encodedBody = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: mergedHeaders);
        break;
      case 'POST':
        response = await _client.post(
          uri,
          headers: mergedHeaders,
          body: encodedBody,
        );
        break;
      case 'PUT':
        response = await _client.put(
          uri,
          headers: mergedHeaders,
          body: encodedBody,
        );
        break;
      case 'DELETE':
        response = await _client.delete(
          uri,
          headers: mergedHeaders,
          body: encodedBody,
        );
        break;
      default:
        throw ApiException(
          statusCode: 0,
          message: 'Unsupported method: $method',
        );
    }

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
}
