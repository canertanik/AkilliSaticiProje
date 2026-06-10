class StoreSettingsModel {
  final List<String> popularCategories;
  final List<String> popularBrands;

  const StoreSettingsModel({
    required this.popularCategories,
    required this.popularBrands,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    return StoreSettingsModel(
      popularCategories: List<String>.from(json['popularCategories'] ?? []),
      popularBrands: List<String>.from(json['popularBrands'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'popularCategories': popularCategories,
      'popularBrands': popularBrands,
    };
  }
}
