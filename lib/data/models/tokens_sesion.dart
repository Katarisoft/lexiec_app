/// Respuesta de `/auth/token`, `/auth/refrescar` y `/auth/cambiar-clave`.
class TokensSesion {
  const TokensSesion({
    required this.accessToken,
    required this.expiresIn,
    this.tokenType = 'bearer',
    this.refreshToken,
    this.refreshExpiresIn,
  });

  factory TokensSesion.fromJson(Map<String, dynamic> json) => TokensSesion(
    accessToken: json['access_token'] as String,
    tokenType: json['token_type'] as String? ?? 'bearer',
    expiresIn: json['expires_in'] as int,
    refreshToken: json['refresh_token'] as String?,
    refreshExpiresIn: json['refresh_expires_in'] as int?,
  );

  final String accessToken;
  final String tokenType;

  /// Segundos de validez del access token.
  final int expiresIn;
  final String? refreshToken;
  final int? refreshExpiresIn;

  // Sin toJson ni toString con valores: los tokens no se serializan ni se imprimen.
}
