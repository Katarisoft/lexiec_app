import 'package:dio/dio.dart';

import 'almacen_tokens.dart';
import 'eventos_sesion.dart';

/// Agrega el access token y, ante un 401, renueva la sesión con el refresh
/// token y reintenta la petición original (guía de la API, § 3).
///
/// Es un [QueuedInterceptor]: los errores se procesan de a uno, así que si
/// varias peticiones reciben 401 a la vez se hace **una sola** renovación y las
/// demás reutilizan el token nuevo. Los reintentos y la renovación usan
/// [dioBase] (sin este interceptor) para no bloquear la cola.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({required this.almacen, required this.dioBase, required this.eventos});

  final AlmacenTokens almacen;

  /// Cliente sin este interceptor: renovación y reintentos.
  final Dio dioBase;
  final EventosSesion eventos;

  static const String _tokenUsado = 'auth.token_usado';
  static const String _reintentado = 'auth.reintentado';

  /// Rutas que no llevan access token: un 401 en ellas no es "sesión expirada".
  static const Set<String> rutasPublicas = {'/auth/token', '/auth/registro', '/auth/refrescar', '/auth/cerrar-sesion'};

  static bool esPublica(RequestOptions opciones) => rutasPublicas.contains(opciones.path);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!esPublica(options)) {
      final token = await almacen.leerAccess();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        options.extra[_tokenUsado] = token;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opciones = err.requestOptions;
    if (err.response?.statusCode != 401 || esPublica(opciones) || opciones.extra[_reintentado] == true) {
      return handler.next(err);
    }

    // ¿Otra petición ya renovó el token mientras esta esperaba en la cola?
    final actual = await almacen.leerAccess();
    if (actual != null && actual != opciones.extra[_tokenUsado]) {
      return _reintentar(opciones, actual, handler);
    }

    final refresh = await almacen.leerRefresh();
    if (refresh == null) {
      await _expirar();
      return handler.next(err);
    }

    final String nuevoAccess;
    try {
      final respuesta = await dioBase.post<Map<String, dynamic>>('/auth/refrescar', data: {'refresh_token': refresh});
      final datos = respuesta.data!;
      nuevoAccess = datos['access_token'] as String;
      await almacen.guardar(access: nuevoAccess, refresh: datos['refresh_token'] as String?);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _expirar(); // refresh inválido, revocado o reutilizado: volver al login
      }
      // Sin red durante la renovación: se conserva la sesión y se informa el error original.
      return handler.next(err);
    }
    return _reintentar(opciones, nuevoAccess, handler);
  }

  Future<void> _reintentar(RequestOptions opciones, String token, ErrorInterceptorHandler handler) async {
    opciones
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[_tokenUsado] = token
      ..extra[_reintentado] = true;
    try {
      handler.resolve(await dioBase.fetch<dynamic>(opciones));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) await _expirar();
      handler.next(e);
    }
  }

  Future<void> _expirar() async {
    await almacen.borrar();
    eventos.notificarExpiracion();
  }
}
