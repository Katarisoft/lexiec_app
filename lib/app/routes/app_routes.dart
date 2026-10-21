/// Nombres de rutas de la app.
abstract final class AppRoutes {
  static const String inicio = '/';
  static const String bienvenida = '/bienvenida';
  static const String login = '/login';
  static const String registro = '/registro';

  /// Lista principal (protegida).
  static const String consultas = '/consultas';

  /// Detalle de una consulta (protegida).
  static const String consultaPatron = '/consultas/:id';
  static String consulta(String id) => '/consultas/$id';
}
