import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'api_config.dart';
import 'auth_service.dart';

class OrderService {
  final AuthService authService;

  OrderService(this.authService);

  Future<AdminDashboardMetrics> getAdminDashboard() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders/admin/dashboard');
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
        throw Exception('Dashboard verileri alınamadı');
      }

      return AdminDashboardMetrics.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on TimeoutException {
      throw Exception('Dashboard isteği zaman aşımına uğradı');
    }
  }

  Future<String?> createOrder({
    required CheckoutDetails checkout,
    required List<CartItem> items,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders');
    final payload = {
      'customerName': checkout.customerName,
      'customerEmail': checkout.customerEmail,
      'customerPhone': checkout.customerPhone,
      'deliveryCity': checkout.deliveryCity,
      'deliveryDistrict': checkout.deliveryDistrict,
      'deliveryNeighborhood': checkout.deliveryNeighborhood,
      'deliveryAddressLine': checkout.deliveryAddressLine,
      'postalCode': checkout.postalCode,
      'addressTitle': checkout.addressTitle,
      'orderNote': checkout.orderNote,
      'paymentMethod': checkout.paymentMethod,
      'items':
          items
              .map(
                (item) => {
                  'productId': item.product.id,
                  'productTitle': item.product.title,
                  'unitPrice': item.product.getDisplayPrice(authService.isLoggedIn),
                  'quantity': item.quantity,
                  'lineTotal': item.getLineTotal(authService.isLoggedIn),
                },
              )
              .toList(),
    };

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: authService.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      return 'Sipariş servisi zaman aşımına uğradı';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final message = body['message']?.toString();
          if (message != null && message.isNotEmpty) {
            return message;
          }

          final title = body['title']?.toString();
          if (title != null && title.isNotEmpty) {
            return title;
          }
        }
      } catch (_) {
        // Fall back to generic message below.
      }
      return 'Sipariş oluşturulamadı (HTTP ${response.statusCode})';
    }

    return null;
  }

  Future<List<OrderModel>> getAdminOrders() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders');
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
        throw Exception('Siparişler alınamadı');
      }

      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    } on TimeoutException {
      throw Exception('Sipariş listesi zaman aşımına uğradı');
    }
  }

  Future<String?> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/orders/$orderId/status?status=$status',
    );
    http.Response response;
    try {
      response = await http
          .put(uri, headers: authService.authHeaders)
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      return 'Sipariş güncelleme zaman aşımına uğradı';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return 'Sipariş durumu güncellenemedi';
    }
    return null;
  }

  /// Tamamlanan veya iptal edilen siparişi siler. Hata varsa mesaj döner, null ise başarılı.
  Future<String?> deleteOrder(int orderId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders/$orderId');
    http.Response response;
    try {
      response = await http
          .delete(uri, headers: authService.authHeaders)
          .timeout(ApiConfig.requestTimeout);
    } on TimeoutException {
      return 'Sipariş silme zaman aşımına uğradı';
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['message']?.toString() ?? 'Sipariş silinemedi';
      } catch (_) {
        return 'Sipariş silinemedi (HTTP ${response.statusCode})';
      }
    }
    return null;
  }

  Future<SalesListResponse> getSalesList({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/orders/admin/sales?page=$page&pageSize=$pageSize',
      );
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
        throw Exception('Satış listesi alınamadı');
      }

      return SalesListResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on TimeoutException {
      throw Exception('Satış listesi isteği zaman aşımına uğradı');
    }
  }
}

class CheckoutDetails {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String deliveryCity;
  final String deliveryDistrict;
  final String deliveryNeighborhood;
  final String deliveryAddressLine;
  final String postalCode;
  final String addressTitle;
  final String? orderNote;
  final String paymentMethod;

  const CheckoutDetails({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.deliveryCity,
    required this.deliveryDistrict,
    required this.deliveryNeighborhood,
    required this.deliveryAddressLine,
    required this.postalCode,
    required this.addressTitle,
    required this.orderNote,
    required this.paymentMethod,
  });
}

class SalesItemDetail {
  final String productTitle;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const SalesItemDetail({
    required this.productTitle,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory SalesItemDetail.fromJson(Map<String, dynamic> json) {
    return SalesItemDetail(
      productTitle: (json['productTitle'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SalesListItem {
  final int orderId;
  final String customerName;
  final String customerEmail;
  final int itemsCount;
  final int totalQuantity;
  final double totalAmount;
  final DateTime createdAtUtc;
  final String status;
  final List<SalesItemDetail> items;

  const SalesListItem({
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.itemsCount,
    required this.totalQuantity,
    required this.totalAmount,
    required this.createdAtUtc,
    required this.status,
    required this.items,
  });

  factory SalesListItem.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return SalesListItem(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      itemsCount: (json['itemsCount'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['totalQuantity'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      createdAtUtc:
          DateTime.tryParse((json['createdAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: (json['status'] ?? '').toString(),
      items:
          itemsJson
              .whereType<Map<String, dynamic>>()
              .map(SalesItemDetail.fromJson)
              .toList(),
    );
  }
}

class SalesListResponse {
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final List<SalesListItem> items;

  const SalesListResponse({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.items,
  });

  factory SalesListResponse.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return SalesListResponse(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      items:
          itemsJson
              .whereType<Map<String, dynamic>>()
              .map(SalesListItem.fromJson)
              .toList(),
    );
  }
}

class AdminDashboardStatusItem {
  final String status;
  final int count;

  const AdminDashboardStatusItem({required this.status, required this.count});

  factory AdminDashboardStatusItem.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatusItem(
      status: (json['status'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardRecentSale {
  final int orderId;
  final int? productId;
  final String productTitle;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final DateTime soldAtUtc;
  final String customerName;
  final String status;

  const AdminDashboardRecentSale({
    required this.orderId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.soldAtUtc,
    required this.customerName,
    required this.status,
  });

  factory AdminDashboardRecentSale.fromJson(Map<String, dynamic> json) {
    return AdminDashboardRecentSale(
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt(),
      productTitle: (json['productTitle'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      soldAtUtc:
          DateTime.tryParse((json['soldAtUtc'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      customerName: (json['customerName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class AdminDashboardMetrics {
  final int totalProducts;
  final int totalSalesCount;
  final double totalRevenue;
  final List<AdminDashboardStatusItem> statusDistribution;
  final List<AdminDashboardRecentSale> recentSales;

  const AdminDashboardMetrics({
    required this.totalProducts,
    required this.totalSalesCount,
    required this.totalRevenue,
    required this.statusDistribution,
    required this.recentSales,
  });

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    final statusJson = (json['statusDistribution'] as List?) ?? const [];
    final salesJson = (json['recentSales'] as List?) ?? const [];

    return AdminDashboardMetrics(
      totalProducts: (json['totalProducts'] as num?)?.toInt() ?? 0,
      totalSalesCount: (json['totalSalesCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      statusDistribution:
          statusJson
              .whereType<Map<String, dynamic>>()
              .map(AdminDashboardStatusItem.fromJson)
              .toList(),
      recentSales:
          salesJson
              .whereType<Map<String, dynamic>>()
              .map(AdminDashboardRecentSale.fromJson)
              .toList(),
    );
  }
}
