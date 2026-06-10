class OrderItemModel {
  final int id;
  final int? productId;
  final String productTitle;
  final double unitPrice;
  final int quantity;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.unitPrice,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as int,
      productId: json['productId'] as int?,
      productTitle: (json['productTitle'] ?? '') as String,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] ?? 0) as int,
    );
  }
}

class OrderModel {
  final int id;
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
  final double totalAmount;
  final String status;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
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
    required this.totalAmount,
    required this.status,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return OrderModel(
      id: json['id'] as int,
      customerName: (json['customerName'] ?? '') as String,
      customerEmail: (json['customerEmail'] ?? '') as String,
      customerPhone: (json['customerPhone'] ?? '') as String,
      deliveryCity: (json['deliveryCity'] ?? '') as String,
      deliveryDistrict: (json['deliveryDistrict'] ?? '') as String,
      deliveryNeighborhood: (json['deliveryNeighborhood'] ?? '') as String,
      deliveryAddressLine: (json['deliveryAddressLine'] ?? '') as String,
      postalCode: (json['postalCode'] ?? '') as String,
      addressTitle: (json['addressTitle'] ?? '') as String,
      orderNote: (json['orderNote'] as String?),
      paymentMethod: (json['paymentMethod'] ?? '') as String,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      status: (json['status'] ?? 'Pending').toString(),
      items:
          itemsJson
              .whereType<Map<String, dynamic>>()
              .map(OrderItemModel.fromJson)
              .toList(),
    );
  }
}
