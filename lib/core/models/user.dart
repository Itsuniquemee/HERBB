class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profileImage,
    required this.createdAt,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
      metadata: json['metadata'],
    );
  }
}

enum UserRole {
  farmer,
  consumer,
}
