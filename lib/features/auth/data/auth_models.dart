class LoginRequest {
  final String email;
  final String password;
  const LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String role;
  final String? phone;
  final String? businessName;
  final String? businessType;
  final String? address;
  final double? lat;
  final double? lng;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.businessName,
    this.businessType,
    this.address,
    this.lat,
    this.lng,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    if (businessName != null) map['businessName'] = businessName;
    if (businessType != null) map['businessType'] = businessType;
    if (address != null) map['address'] = address;
    if (lat != null) map['lat'] = lat;
    if (lng != null) map['lng'] = lng;
    return map;
  }
}

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String?,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String? fcmToken;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.fcmToken,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        role: json['role'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        fcmToken: json['fcmToken'] as String?,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'avatarUrl': avatarUrl,
        'fcmToken': fcmToken,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}
