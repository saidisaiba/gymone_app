/// A gym account (member, coach or admin) as returned by the API.
///
/// The server has used several shapes over time, so parsing is tolerant:
///  * numbers may arrive as strings ("1") because PDO returns strings;
///  * membership data may be flat (`is_active`, `expiry_date`) or nested in
///    `subscription`;
///  * members may have role `client`, `user` or `member`.
class UserModel {
  final int id;
  final String name;
  final String email;

  /// Normalised role: `client`, `coach` or `admin`.
  final String role;

  /// The role exactly as the server stores it (used when sending updates back).
  final String serverRole;
  final String phoneNumber;
  final String memberNumber;
  final String birthdate;
  final String profileImage;
  final bool isActive;
  final String expiryDate;
  final String membershipType;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    String? serverRole,
    this.phoneNumber = '',
    this.memberNumber = '',
    this.birthdate = '',
    this.profileImage = '',
    this.isActive = false,
    this.expiryDate = 'N/A',
    this.membershipType = '',
  }) : serverRole = serverRole ?? role;

  bool get isAdmin => role == 'admin';
  bool get isCoach => role == 'coach';
  bool get isMember => role == 'client';

  static const memberRoleNames = {'client', 'user', 'member'};

  static String normaliseRole(String raw) {
    final r = raw.toLowerCase().trim();
    if (r == 'admin' || r == 'coach') return r;
    return 'client';
  }

  static String _str(dynamic v) => v == null ? '' : v.toString();

  static bool _truthy(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] is Map ? Map<String, dynamic>.from(json['subscription']) : const <String, dynamic>{};
    dynamic pick(String key) => json[key] ?? sub[key];

    final expiry = _str(pick('expiry_date'));
    var active = _truthy(pick('is_active'));
    // A flag left at 1 after the expiry date has passed is not an active membership.
    final parsedExpiry = DateTime.tryParse(expiry);
    if (active && parsedExpiry != null) {
      final today = DateTime.now();
      active = !parsedExpiry.isBefore(DateTime(today.year, today.month, today.day));
    }

    final rawRole = _str(json['role']).isEmpty ? 'client' : _str(json['role']);
    return UserModel(
      id: int.tryParse(_str(json['id'])) ?? 0,
      name: _str(json['name']),
      email: _str(json['email']),
      role: normaliseRole(rawRole),
      serverRole: rawRole,
      phoneNumber: _str(json['phone_number']),
      memberNumber: _str(json['member_number']),
      birthdate: _str(json['birthdate']),
      profileImage: _str(json['profile_image'] ?? json['profile_picture'] ?? json['avatar']),
      isActive: active,
      expiryDate: expiry.isEmpty ? 'N/A' : expiry,
      membershipType: _str(pick('membership_type')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': serverRole,
        'phone_number': phoneNumber,
        'member_number': memberNumber,
        'birthdate': birthdate,
        'profile_image': profileImage,
        'is_active': isActive ? 1 : 0,
        'expiry_date': expiryDate,
        'membership_type': membershipType,
      };

  UserModel copyWith({bool? isActive, String? expiryDate}) => UserModel(
        id: id,
        name: name,
        email: email,
        role: role,
        serverRole: serverRole,
        phoneNumber: phoneNumber,
        memberNumber: memberNumber,
        birthdate: birthdate,
        profileImage: profileImage,
        isActive: isActive ?? this.isActive,
        expiryDate: expiryDate ?? this.expiryDate,
        membershipType: membershipType,
      );
}
