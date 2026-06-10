class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String storeName;
  final bool isAdmin;
  final int pawPoints;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.storeName,
    required this.isAdmin,
    this.pawPoints = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      storeName: (json['storeName'] ?? '') as String,
      isAdmin: (json['isAdmin'] ?? false) as bool,
      pawPoints: (json['pawPoints'] ?? 0) as int,
    );
  }
}
