import 'dart:math';

import 'package:dio/dio.dart';

/// Agrega `X-Request-ID` a cada petición: el mismo ID aparece en los logs del
/// backend y permite rastrear un error reportado desde la app.
class RequestIdInterceptor extends Interceptor {
  RequestIdInterceptor({Random? aleatorio}) : _aleatorio = aleatorio ?? Random.secure();

  final Random _aleatorio;

  static const String encabezado = 'X-Request-ID';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent(encabezado, generar);
    handler.next(options);
  }

  /// 32 caracteres hexadecimales (formato aceptado por la API: 8–64 de `A-Za-z0-9._-`).
  String generar() => List.generate(16, (_) => _aleatorio.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}
