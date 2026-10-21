import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../errors/mapeador_errores.dart';
import 'almacen_tokens.dart';
import 'auth_interceptor.dart';
import 'eventos_sesion.dart';
import 'request_id_interceptor.dart';

/// Cliente HTTP de la app. Los datasources lo usan a través de [ejecutar],
/// que convierte cualquier error de red en una [AppException] tipada.
class ApiClient {
  ApiClient({
    required AlmacenTokens almacen,
    required EventosSesion eventos,
    String? baseUrl,
    HttpClientAdapter? adaptador, // para pruebas
  }) {
    final opciones = BaseOptions(
      baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: tiempoNormal,
      headers: {'Accept': 'application/json'},
    );
    dioBase = Dio(opciones)..interceptors.add(RequestIdInterceptor());
    dio = Dio(opciones)
      ..interceptors.addAll([
        RequestIdInterceptor(),
        AuthInterceptor(almacen: almacen, dioBase: dioBase, eventos: eventos),
      ]);
    if (adaptador != null) {
      dio.httpClientAdapter = adaptador;
      dioBase.httpClientAdapter = adaptador;
    }
  }

  /// Con token y renovación automática: usar para todas las peticiones.
  late final Dio dio;

  /// Sin interceptor de autenticación: renovación y reintentos internos.
  late final Dio dioBase;

  static const Duration tiempoNormal = Duration(seconds: 30);

  /// Las respuestas del modelo de IA pueden tardar (guía § 6.5: timeout ≥ 300 s).
  static const Duration tiempoIA = Duration(seconds: 300);

  /// Ejecuta una petición y traduce los errores a [AppException].
  static Future<T> ejecutar<T>(Future<T> Function() peticion) async {
    try {
      return await peticion();
    } on DioException catch (e) {
      throw await MapeadorErrores.desdeDio(e);
    }
  }
}
