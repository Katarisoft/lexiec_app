/// Errores tipados de la capa de datos. Se convierten a texto solo en los
/// controladores (ver `controllers/mensajes_error.dart`).
sealed class AppException implements Exception {
  const AppException({this.detalle, this.statusCode});

  /// Mensaje del servidor (`detail`), en español, si lo envió.
  final String? detalle;
  final int? statusCode;

  @override
  String toString() => '$runtimeType(${statusCode ?? '-'})';
}

/// 400: datos inválidos (p. ej. "La clave actual es incorrecta.").
final class BadRequestException extends AppException {
  const BadRequestException({super.detalle}) : super(statusCode: 400);
}

/// 401: sin sesión, token expirado o credenciales incorrectas.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({super.detalle}) : super(statusCode: 401);
}

/// 402 con `codigo: sin_consultas`: agotó las consultas gratuitas del mes y no tiene saldo pagado.
final class QuotaExceededException extends AppException {
  const QuotaExceededException({super.detalle}) : super(statusCode: 402);
}

/// 403: sin permisos (p. ej. código de invitación inválido).
final class ForbiddenException extends AppException {
  const ForbiddenException({super.detalle}) : super(statusCode: 403);
}

/// 404: el recurso no existe o es de otro usuario.
final class NotFoundException extends AppException {
  const NotFoundException({super.detalle}) : super(statusCode: 404);
}

/// 409: dato duplicado (usuario o correo ya registrado).
final class ConflictException extends AppException {
  const ConflictException({super.detalle}) : super(statusCode: 409);
}

/// 422: validación. [campos] = campo → mensaje en español; `_general` para errores del formulario.
final class ValidationException extends AppException {
  const ValidationException({this.campos = const {}, super.detalle}) : super(statusCode: 422);

  final Map<String, String> campos;

  static const String general = '_general';
}

/// 429: demasiadas peticiones (por usuario en la API o por IP en Nginx).
final class RateLimitException extends AppException {
  const RateLimitException({this.reintentarEn, super.detalle}) : super(statusCode: 429);

  final Duration? reintentarEn;
}

/// 503 con `codigo: ocupado`: el modelo de IA está saturado.
final class ServiceBusyException extends AppException {
  const ServiceBusyException({this.reintentarEn, super.detalle}) : super(statusCode: 503);

  final Duration? reintentarEn;
}

/// 5xx genérico (incluye 502/503 de Nginx con el backend caído).
final class ServerException extends AppException {
  const ServerException({super.detalle, super.statusCode});
}

/// Tiempo agotado (del cliente o 504 del servidor).
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException({super.detalle, super.statusCode});
}

/// Sin conexión o servidor inalcanzable.
final class NetworkException extends AppException {
  const NetworkException();
}

/// La operación se canceló (p. ej. la persona salió de la pantalla). No se muestra.
final class CancelledException extends AppException {
  const CancelledException();
}

/// Cualquier otro caso.
final class UnknownException extends AppException {
  const UnknownException({super.statusCode});
}
