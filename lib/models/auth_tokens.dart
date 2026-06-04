class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
    this.expiresIn,
    this.refreshExpiresIn,
  });

  final String access;
  final String refresh;
  final int? expiresIn;
  final int? refreshExpiresIn;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final access = (json['access'] ?? json['access_token']) as String?;
    final refresh = (json['refresh'] ?? json['refresh_token']) as String?;
    if (access == null || refresh == null) {
      throw const FormatException('Missing access/refresh in tokens payload');
    }
    return AuthTokens(
      access: access,
      refresh: refresh,
      expiresIn: (json['expires_in'] as num?)?.toInt(),
      refreshExpiresIn: (json['refresh_expires_in'] as num?)?.toInt(),
    );
  }
}
