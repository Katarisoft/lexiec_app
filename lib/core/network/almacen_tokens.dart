/// Acceso a los tokens de sesión. La implementación real usa almacenamiento
/// seguro (`data/datasources/local_tokens_datasource.dart`); las pruebas usan
/// una en memoria.
abstract interface class AlmacenTokens {
  Future<String?> leerAccess();

  Future<String?> leerRefresh();

  /// Guarda el access token y, si viene, el refresh token (rotación).
  Future<void> guardar({required String access, String? refresh});

  Future<void> borrar();
}
