import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';

import '../helpers/red_falsa.dart';

Future<AppException> _errorDe(ResponseBody respuesta, {ResponseType tipo = ResponseType.json}) async {
  final cliente = ApiClient(
    almacen: AlmacenEnMemoria(access: 'a'),
    eventos: EventosSesion(),
    baseUrl: 'http://api.test/api/v1',
    adaptador: AdaptadorFalso((_) async => respuesta),
  );
  try {
    await ApiClient.ejecutar(() => cliente.dio.get<dynamic>('/conversaciones', options: Options(responseType: tipo)));
  } on AppException catch (e) {
    return e;
  }
  fail('se esperaba una AppException');
}

void main() {
  test('400, 403, 404 y 409 conservan el detalle del servidor', () async {
    expect(
      (await _errorDe(respuestaJson(400, {'detail': 'La clave actual es incorrecta.'}))).detalle,
      'La clave actual es incorrecta.',
    );
    expect(await _errorDe(respuestaJson(403, {'detail': 'Código de invitación inválido.'})), isA<ForbiddenException>());
    expect(await _errorDe(respuestaJson(404, {'detail': 'Conversación no encontrada.'})), isA<NotFoundException>());
    expect(await _errorDe(respuestaJson(409, {'detail': 'El correo ya está registrado.'})), isA<ConflictException>());
  });

  test('422 traduce los errores por campo al español', () async {
    final e =
        await _errorDe(
              respuestaJson(422, {
                'detail': [
                  {
                    'type': 'string_too_short',
                    'loc': ['body', 'clave'],
                    'msg': 'String should have at least 12 characters',
                    'ctx': {'min_length': 12},
                  },
                  {
                    'type': 'value_error',
                    'loc': ['body', 'correo'],
                    'msg': 'value is not a valid email address: x',
                  },
                  {
                    'type': 'value_error',
                    'loc': ['body'],
                    'msg': 'Value error, La clave no debe contener el nombre de usuario.',
                  },
                ],
              }),
            )
            as ValidationException;
    expect(e.campos['clave'], 'Debe tener al menos 12 caracteres.');
    expect(e.campos['correo'], 'El correo electrónico no es válido.');
    expect(e.campos[ValidationException.general], 'La clave no debe contener el nombre de usuario.');
  });

  test('429 de la API y de Nginx (HTML) con Retry-After', () async {
    final api =
        await _errorDe(
              respuestaJson(
                429,
                {'detail': '…', 'codigo': 'limite_usuario'},
                encabezados: {
                  'retry-after': ['42'],
                },
              ),
            )
            as RateLimitException;
    expect(api.reintentarEn, const Duration(seconds: 42));
    expect(await _errorDe(respuestaHtml(429)), isA<RateLimitException>());
  });

  test('503 "ocupado" de la API es distinto del 503 de Nginx', () async {
    final ocupado =
        await _errorDe(
              respuestaJson(
                503,
                {'detail': '…', 'codigo': 'ocupado'},
                encabezados: {
                  'retry-after': ['12'],
                },
              ),
            )
            as ServiceBusyException;
    expect(ocupado.reintentarEn, const Duration(seconds: 12));
    expect(await _errorDe(respuestaHtml(503)), isA<ServerException>());
    expect(await _errorDe(respuestaHtml(502)), isA<ServerException>());
  });

  test('504 es tiempo agotado y 500 error del servidor', () async {
    expect(
      await _errorDe(respuestaJson(504, {'detail': 'El servicio de IA tardó demasiado en responder.'})),
      isA<RequestTimeoutException>(),
    );
    expect(
      await _errorDe(respuestaJson(500, {'detail': 'No fue posible procesar la consulta.'})),
      isA<ServerException>(),
    );
  });

  test('el cuerpo de error de una petición en streaming también se interpreta', () async {
    final e = await _errorDe(respuestaJson(404, {'detail': 'Conversación no encontrada.'}), tipo: ResponseType.stream);
    expect(e, isA<NotFoundException>());
    expect(e.detalle, 'Conversación no encontrada.');
  });

  test('sin conexión y timeouts', () async {
    final cliente = ApiClient(
      almacen: AlmacenEnMemoria(),
      eventos: EventosSesion(),
      baseUrl: 'http://api.test/api/v1',
      adaptador: AdaptadorFalso((o) async => throw DioException.connectionError(requestOptions: o, reason: 'sin red')),
    );
    await expectLater(
      ApiClient.ejecutar(() => cliente.dio.get<dynamic>('/documentos')),
      throwsA(isA<NetworkException>()),
    );
    cliente.dio.httpClientAdapter = AdaptadorFalso(
      (o) async => throw DioException.receiveTimeout(timeout: const Duration(seconds: 1), requestOptions: o),
    );
    await expectLater(
      ApiClient.ejecutar(() => cliente.dio.get<dynamic>('/documentos')),
      throwsA(isA<RequestTimeoutException>()),
    );
  });
}
