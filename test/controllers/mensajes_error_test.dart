import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/controllers/mensajes_error.dart';
import 'package:lexiec/core/errors/app_exception.dart';

void main() {
  test('401, 400, 422, 5xx y sin conexión dan mensajes distintos (rúbrica § 7)', () {
    final mensajes = [
      const UnauthorizedException(),
      const BadRequestException(),
      const ValidationException(),
      const ServerException(statusCode: 500),
      const NetworkException(),
      const RequestTimeoutException(),
    ].map(MensajesError.de).toList();
    expect(mensajes.toSet(), hasLength(mensajes.length));
  });

  test('usa el detalle en español del servidor cuando aporta información', () {
    expect(
      MensajesError.de(const BadRequestException(detalle: 'La clave actual es incorrecta.')),
      'La clave actual es incorrecta.',
    );
    expect(
      MensajesError.de(const ConflictException(detalle: 'El correo ya está registrado.')),
      'El correo ya está registrado.',
    );
  });

  test('422: prioriza el error general y luego el primer campo', () {
    expect(
      MensajesError.de(const ValidationException(campos: {'clave': 'Debe tener al menos 12 caracteres.'})),
      'Debe tener al menos 12 caracteres.',
    );
    expect(
      MensajesError.de(const ValidationException(campos: {'_general': 'General.', 'clave': 'Campo.'})),
      'General.',
    );
  });

  test('429 y 503 indican cuándo reintentar', () {
    expect(MensajesError.de(const RateLimitException(reintentarEn: Duration(seconds: 30))), contains('30 s'));
    expect(MensajesError.de(const ServiceBusyException(reintentarEn: Duration(seconds: 12))), contains('12 s'));
  });

  test('402: consultas agotadas, sin cerrar sesión', () {
    expect(MensajesError.de(const QuotaExceededException()), contains('paquete'));
    expect(MensajesError.requiereLogin(const QuotaExceededException()), isFalse);
  });

  test('solo el 401 obliga a volver al login', () {
    expect(MensajesError.requiereLogin(const UnauthorizedException()), isTrue);
    expect(MensajesError.requiereLogin(const ServerException()), isFalse);
  });
}
