import 'dart:typed_data';

enum ProductStatus { draft, published }

class Product {
  final String id;
  String imageUrl;
  String title;
  String description;
  String priceRange;
  String category;
  bool isDraft;
  bool aiGenerated;
  double? minPrice;
  double? maxPrice;
  ProductStatus status;
  // WEB DESTEĞİ
  final Uint8List? webImageBytes;

  Product({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.priceRange,
    required this.category,
    required this.isDraft,
    required this.aiGenerated,
    this.minPrice,
    this.maxPrice,
    ProductStatus? status,
    this.webImageBytes,
  }) : status =
           status ?? (isDraft ? ProductStatus.draft : ProductStatus.published);

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['Id'] ?? json['_id'] ?? '';
    final minPrice = _toDouble(
      json['minPrice'] ?? json['MinPrice'] ?? json['min_price'],
    );
    final maxPrice = _toDouble(
      json['maxPrice'] ?? json['MaxPrice'] ?? json['max_price'],
    );
    final status = _parseStatus(json['status'] ?? json['Status']);
    final range = _formatPriceRange(minPrice, maxPrice);
    return Product(
      id: id.toString(),
      imageUrl:
          (json['imageUrl'] ??
                  json['ImageUrl'] ??
                  json['image_url'] ??
                  json['image'] ??
                  '')
              .toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      description:
          (json['description'] ?? json['Description'] ?? '').toString(),
      priceRange:
          range.isNotEmpty
              ? range
              : (json['priceRange'] ?? json['price_range'] ?? '').toString(),
      category: (json['category'] ?? json['Category'] ?? '').toString(),
      isDraft:
          status == ProductStatus.draft ||
          (json['isDraft'] ?? json['is_draft'] ?? false) == true,
      aiGenerated:
          (json['aiGenerated'] ??
              json['AiGenerated'] ??
              json['isAiGenerated'] ??
              json['IsAiGenerated'] ??
              json['ai_generated'] ??
              false) ==
          true,
      minPrice: minPrice,
      maxPrice: maxPrice,
      status: status,
      webImageBytes: null,
    );
  }

  Map<String, dynamic> toJson() {
    final parsed = _parsePriceRange(priceRange);
    final sendMin = minPrice ?? parsed.min;
    final sendMax = maxPrice ?? parsed.max;
    final sendStatus =
        status == ProductStatus.published ? 'Published' : 'Draft';
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'minPrice': sendMin,
      'maxPrice': sendMax,
      'category': category,
      'isAiGenerated': aiGenerated,
      'status': sendStatus,
    };
  }

  Product copyWith({
    String? imageUrl,
    String? title,
    String? description,
    String? priceRange,
    String? category,
    bool? isDraft,
    bool? aiGenerated,
    double? minPrice,
    double? maxPrice,
    ProductStatus? status,
    Uint8List? webImageBytes,
  }) {
    return Product(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      priceRange: priceRange ?? this.priceRange,
      category: category ?? this.category,
      isDraft: isDraft ?? this.isDraft,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      status: status ?? this.status,
      webImageBytes: webImageBytes ?? this.webImageBytes,
    );
  }

  static ProductStatus _parseStatus(dynamic value) {
    if (value is String) {
      final v = value.toLowerCase();
      if (v.contains('publish')) return ProductStatus.published;
      if (v.contains('draft')) return ProductStatus.draft;
    }
    if (value is int) {
      if (value == 1) return ProductStatus.published;
      return ProductStatus.draft;
    }
    return ProductStatus.draft;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final s = value.toString().replaceAll(',', '.');
    return double.tryParse(s);
  }

  static _PriceRange _parsePriceRange(String input) {
    final matches = RegExp(r'[\d.,]+').allMatches(input);
    final numbers =
        matches
            .map((m) => m.group(0) ?? '')
            .map((s) => s.replaceAll(',', '.'))
            .map(double.tryParse)
            .whereType<double>()
            .toList();
    if (numbers.isEmpty) return _PriceRange(null, null);
    if (numbers.length == 1) return _PriceRange(numbers.first, numbers.first);
    return _PriceRange(numbers.first, numbers.last);
  }

  static String _formatPriceRange(double? min, double? max) {
    if (min == null && max == null) return '';
    if (min != null && max != null) {
      return '₺${min.toStringAsFixed(0)} - ₺${max.toStringAsFixed(0)}';
    }
    final value = (min ?? max) ?? 0;
    return '₺${value.toStringAsFixed(0)}';
  }
}

class _PriceRange {
  final double? min;
  final double? max;

  const _PriceRange(this.min, this.max);
}
