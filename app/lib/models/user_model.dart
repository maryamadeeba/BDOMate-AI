class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatar;
  final String department;
  final String phone;
  final DateTime createdAt;
  bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    required this.department,
    required this.phone,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: json['role'] ?? 'BDO',
        avatar: json['avatar'],
        department: json['department'] ?? '',
        phone: json['phone'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
        'department': department,
        'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'isActive': isActive,
      };
}
