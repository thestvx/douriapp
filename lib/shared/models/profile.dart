class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.email,
    required this.appRole,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String appRole;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        fullName: (map['full_name'] ?? '') as String,
        phoneNumber: map['phone_number'] as String?,
        email: map['email'] as String?,
        appRole: (map['app_role'] ?? 'customer') as String,
        avatarUrl: map['avatar_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'app_role': appRole,
        'avatar_url': avatarUrl,
      };
}
