class PetProfileModel {
  final int id;
  final int userId;
  final String name;
  final String species;
  final String? breed;
  final int ageYears;
  final int ageMonths;
  final double? weightKg;
  final bool isNeutered;
  final DateTime createdAt;

  const PetProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    required this.ageYears,
    required this.ageMonths,
    this.weightKg,
    required this.isNeutered,
    required this.createdAt,
  });

  factory PetProfileModel.fromJson(Map<String, dynamic> json) {
    return PetProfileModel(
      id: json['id'] as int,
      userId: json['userId'] as int,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      ageYears: json['ageYears'] as int,
      ageMonths: json['ageMonths'] as int,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      isNeutered: json['isNeutered'] as bool,
      createdAt: DateTime.parse(json['createdAtUtc'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'ageYears': ageYears,
      'ageMonths': ageMonths,
      'weightKg': weightKg,
      'isNeutered': isNeutered,
    };
  }
}
