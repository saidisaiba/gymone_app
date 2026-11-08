class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String memberNumber;
  final String birthdate;
  final String profileImage;
  final bool isActive;
  final String expiryDate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.memberNumber,
    required this.birthdate,
    required this.profileImage,
    required this.isActive,
    required this.expiryDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'client',
      phoneNumber: json['phone_number'] ?? '',
      memberNumber: json['member_number'] ?? '',
      birthdate: json['birthdate'] ?? '',
      profileImage: json['profile_image'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      expiryDate: json['expiry_date'] ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone_number': phoneNumber,
    'member_number': memberNumber,
    'birthdate': birthdate,
    'profile_image': profileImage,
    'is_active': isActive ? 1 : 0,
    'expiry_date': expiryDate,
  };
}
