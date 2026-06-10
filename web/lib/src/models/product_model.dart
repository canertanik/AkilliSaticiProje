class ProductModel {
  final int id;
  final String title;
  final String? description;
  final double? minPrice;
  final double? maxPrice;
  final String? category;
  final String? imageUrl;
  final bool isAiGenerated;
  final String status;
  final int stockQuantity;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.minPrice,
    required this.maxPrice,
    required this.category,
    required this.imageUrl,
    required this.isAiGenerated,
    required this.status,
    this.stockQuantity = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isAiGenerated: (json['isAiGenerated'] ?? false) as bool,
      status: (json['status'] ?? 'Draft').toString(),
      stockQuantity: (json['stockQuantity'] as int?) ?? 0,
    );
  }

}

extension ProductPricing on ProductModel {
  double get basePrice => minPrice ?? maxPrice ?? 0;

  double getDisplayPrice(bool isLoggedIn) {
    if (isLoggedIn) {
      return basePrice * 0.90;
    }
    return basePrice;
  }

  double? getOldPrice(bool isLoggedIn) {
    if (isLoggedIn) {
      return basePrice;
    }
    return null;
  }

  bool getIsDiscounted(bool isLoggedIn) => isLoggedIn;

  int getDiscountPercent(bool isLoggedIn) {
    return isLoggedIn ? 10 : 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'category': category,
      'imageUrl': imageUrl,
      'isAiGenerated': isAiGenerated,
      'status': status,
      'stockQuantity': stockQuantity,
    };
  }
}
