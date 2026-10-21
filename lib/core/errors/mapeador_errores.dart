import 'dart:convert';

import 'package:dio/dio.dart';

import 'app_exception.dart';

/// Convierte errores de `dio` en [AppException] según la guía de la API:
/// cuerpos JSON `{"detail": …, "codigo": …}` de la API y respuestas HTML de Nginx (429/502/503).
abstract final class MapeadorErrores {
  /// Mapea un [DioException]. Es asíncrono porque, en peticiones de streaming,
  /// el cuerpo del error llega como flujo y hay que leerlo.
  static Future<AppException> desdeDio(DioException e) async {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const RequestTimeoutException();
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const NetworkException();
      case DioExceptionType.cancel:
        return const CancelledException();
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final respuesta = e.response;
        if (respuesta == null) {
          return e.type == DioExceptionType.unknown ? const NetworkException() : const UnknownException();
        }
        final cuerpo = await _leerCuerpo(respuesta.data);
        return desdeRespuesta(respuesta.statusCode, cuerpo, respuesta.headers);
    }
  }

  /// Mapea un código HTTP y su cuerpo (ya decodificado) a una excepción tipada.
  static AppException desdeRespuesta(int? status, Object? cuerpo, Headers encabezados) {
    final json = cuerpo is Map<String, dynamic> ? cuerpo : null;
    final detalle = json?['detail'] is String ? json!['detail'] as String : null;
    final codigo = json?['codigo'] as String?;
    final reintentar = _reintentarEn(encabezados);

    switch (status) {
      case 400:
        return BadRequestException(detalle: detalle);
      case 401:
        return UnauthorizedException(detalle: detalle);
      case 402:
        return QuotaExceededException(detalle: detalle);
      case 403:
        return ForbiddenException(detalle: detalle);
      case 404:
        return NotFoundException(detalle: detalle);
      case 409:
        return ConflictException(detalle: detalle);
      case 422:
        return ValidationException(campos: _camposValidacion(json?['detail']));
      case 429:
        return RateLimitException(reintentarEn: reintentar, detalle: detalle);
      case 503 when codigo == 'ocupado':
        return ServiceBusyException(reintentarEn: reintentar, detalle: detalle);
      case 504:
        return RequestTimeoutException(detalle: detalle, statusCode: 504);
    }
    if (status != null && status >= 500) {
      return ServerException(detalle: detalle, statusCode: status);
    }
    return UnknownException(statusCode: status);
  }

  static Future<Object?> _leerCuerpo(Object? datos) async {
    if (datos is ResponseBody) {
      try {
        final texto = await utf8.decodeStream(datos.stream);
        return jsonDecode(texto);
      } on FormatException {
        return null; // HTML de Nginx u otro texto
      }
    }
    if (datos is String) {
      try {
        return jsonDecode(datos);
      } on FormatException {
        return null;
      }
    }
    return datos;
  }

  static Duration? _reintentarEn(Headers encabezados) {
    final valor = int.tryParse(encabezados.value('retry-after') ?? '');
    return valor == null ? null : Duration(seconds: valor);
  }

  /// `{"detail": [{"loc": ["body","clave"], "type": "string_too_short", "ctx": {"min_length": 12}, …}]}`
  static Map<String, String> _camposValidacion(Object? detalle) {
    if (detalle is! List) return const {};
    final campos = <String, String>{};
    for (final error in detalle.whereType<Map<String, dynamic>>()) {
      final ubicacion = (error['loc'] as List<dynamic>? ?? const []).map((e) => '$e').toList();
      final campo = ubicacion.length > 1 ? ubicacion.last : ValidationException.general;
      campos.putIfAbsent(campo, () => _mensajeValidacion(error));
    }
    return campos;
  }

  static String _mensajeValidacion(Map<String, dynamic> error) {
    final ctx = error['ctx'] as Map<String, dynamic>? ?? const {};
    final msg = '${error['msg'] ?? ''}';
    switch (error['type']) {
      case 'missing':
        return 'Este campo es obligatorio.';
      case 'string_too_short':
        return 'Debe tener al menos ${ctx['min_length']} caracteres.';
      case 'string_too_long':
        return 'Debe tener como máximo ${ctx['max_length']} caracteres.';
      case 'string_pattern_mismatch':
        return 'Contiene caracteres no permitidos.';
      case 'value_error':
        if (msg.contains('email')) return 'El correo electrónico no es válido.';
        // Validaciones propias del backend, ya en español: "Value error, La clave no debe…"
        return msg.replaceFirst(RegExp(r'^Value error,\s*'), '');
    }
    return 'Valor no válido.';
  }
}
