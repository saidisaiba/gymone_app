class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'user', 'coach', 'admin'
  final String? profilePicture;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.parse(json['id'].toString()),
      name: json['name'],
      email: json['email'],
      role: json['role'],
      profilePicture: json['profile_picture'] ?? json['avatar'],
    );
  }
}
