import '../core/errors/app_exception.dart';

/// Texto para la persona a partir de un error tipado. Solo lo usan los
/// controladores (`claude.md` § 5): la capa de datos lanza excepciones, no textos.
abstract final class MensajesError {
  static String de(AppException error) => switch (error) {
    BadRequestException(:final detalle) => detalle ?? 'Datos inválidos en la solicitud.',
    UnauthorizedException() => 'Tu sesión expiró. Inicia sesión de nuevo.',
    QuotaExceededException(:final detalle) =>
      detalle ?? 'Usaste tus consultas disponibles. Adquiere un paquete para seguir consultando.',
    ForbiddenException(:final detalle) => detalle ?? 'No tienes permisos para esta acción.',
    NotFoundException() => 'No encontramos lo que buscas. Puede que se haya eliminado.',
    ConflictException(:final detalle) => detalle ?? 'Ese dato ya está registrado.',
    ValidationException(:final campos) =>
      campos[ValidationException.general] ?? campos.values.firstOrNull ?? 'Revisa los datos ingresados.',
    RateLimitException(:final reintentarEn) =>
      'Hiciste muchas preguntas seguidas. ${_espera(reintentarEn, 'Espera un momento')}.',
    ServiceBusyException(:final reintentarEn) =>
      'El asistente está atendiendo a muchas personas. ${_espera(reintentarEn, 'Intenta de nuevo en unos segundos')}.',
    ServerException() => 'Error del servidor. Intenta más tarde.',
    RequestTimeoutException() => 'El servidor tardó demasiado en responder. Intenta de nuevo.',
    NetworkException() => 'Sin conexión. Revisa tu internet e intenta de nuevo.',
    CancelledException() => 'Operación cancelada.',
    UnknownException() => 'Ocurrió un error inesperado. Intenta de nuevo.',
  };

  /// true si el error obliga a volver al login.
  static bool requiereLogin(AppException error) => error is UnauthorizedException;

  static String _espera(Duration? espera, String alternativa) =>
      espera == null ? alternativa : 'Intenta de nuevo en ${espera.inSeconds} s';
}
