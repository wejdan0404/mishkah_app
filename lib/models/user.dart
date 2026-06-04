class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.birthYear,
    this.locale = 'ar',
    this.isActive = true,
    this.isPendingDeletion = false,
    this.lastSeenAt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final int? birthYear;
  final String locale;
  final bool isActive;
  final bool isPendingDeletion;
  final String? lastSeenAt;
  final String? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['email_verified'] as bool? ?? false,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      locale: (json['locale'] as String?) ?? 'ar',
      isActive: json['is_active'] as bool? ?? true,
      isPendingDeletion: json['is_pending_deletion'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  User copyWith({String? name, String? locale}) => User(
        id: id,
        name: name ?? this.name,
        email: email,
        emailVerified: emailVerified,
        birthYear: birthYear,
        locale: locale ?? this.locale,
        isActive: isActive,
        isPendingDeletion: isPendingDeletion,
        lastSeenAt: lastSeenAt,
        createdAt: createdAt,
      );
}
