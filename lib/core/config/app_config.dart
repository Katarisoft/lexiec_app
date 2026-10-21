/// Configuración de entorno (solo valores no secretos).
///
/// La URL del backend se define al compilar:
///   flutter run --dart-define-from-file=.env
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010/api/v1
/// Sin valor, se usa el servidor de producción.
abstract final class AppConfig {
  static const String _urlPorDefecto = 'https://lexiec.katarisoft.com/api/v1';

  static const String _urlDefinida = String.fromEnvironment('API_BASE_URL');

  /// URL base de la API, sin barra final (p. ej. `https://lexiec.katarisoft.com/api/v1`).
  static String get apiBaseUrl => normalizarUrl(_urlDefinida.isEmpty ? _urlPorDefecto : _urlDefinida);

  /// Página de planes y compra (pago manual: el usuario envía su comprobante).
  static const String urlPlanes = 'https://consultaslegales.app/#planes';

  static String normalizarUrl(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');
}
