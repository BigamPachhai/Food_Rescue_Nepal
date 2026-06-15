class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  bool get isCustomer => role == 'CUSTOMER';
  bool get isVendor => role == 'VENDOR';
  bool get isAdmin => role == 'ADMIN';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarUrl': avatarUrl,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  UserEntity copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
  }) =>
      UserEntity(
        id: id,
        name: name ?? this.name,
        email: email,
        phone: phone ?? this.phone,
        role: role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isActive: isActive,
        createdAt: createdAt,
      );
}
