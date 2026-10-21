import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/core/network/request_id_interceptor.dart';

import '../helpers/red_falsa.dart';

const _base = 'http://api.test/api/v1';

/// Servidor falso: el access "valido-N" es aceptado; cualquier otro da 401.
/// /auth/refrescar entrega "valido-2"/"refresh-2" si recibe "refresh-1".
class _Servidor {
  _Servidor({this.refrescarResponde});

  ResponseBody Function()? refrescarResponde;

  Future<ResponseBody> responder(RequestOptions o) async {
    await Future<void>.delayed(const Duration(milliseconds: 5)); // peticiones solapadas
    if (o.path == '/auth/refrescar') {
      if (refrescarResponde != null) return refrescarResponde!();
      final datos = o.data as Map<String, dynamic>;
      return datos['refresh_token'] == 'refresh-1'
          ? respuestaJson(200, {
              'access_token': 'valido-2',
              'token_type': 'bearer',
              'expires_in': 900,
              'refresh_token': 'refresh-2',
              'refresh_expires_in': 2592000,
            })
          : respuestaJson(401, {'detail': 'Sesión expirada o inválida. Inicia sesión de nuevo.'});
    }
    if (o.path == '/auth/token') return respuestaJson(401, {'detail': 'Usuario o clave incorrectos.'});
    final auth = o.headers['Authorization'] as String?;
    if (auth == 'Bearer valido-2') return respuestaJson(200, {'ok': o.path});
    return respuestaJson(401, {'detail': 'Credenciales inválidas o token expirado.'});
  }
}

({ApiClient cliente, AdaptadorFalso red, AlmacenEnMemoria almacen, EventosSesion eventos}) _montar(
  _Servidor servidor, {
  String? access = 'vencido',
  String? refresh = 'refresh-1',
}) {
  final red = AdaptadorFalso(servidor.responder);
  final almacen = AlmacenEnMemoria(access: access, refresh: refresh);
  final eventos = EventosSesion();
  final cliente = ApiClient(almacen: almacen, eventos: eventos, baseUrl: _base, adaptador: red);
  return (cliente: cliente, red: red, almacen: almacen, eventos: eventos);
}

void main() {
  test('agrega Bearer y X-Request-ID en rutas protegidas, y no envía token en las públicas', () async {
    final m = _montar(_Servidor(), access: 'valido-2');
    await m.cliente.dio.get<dynamic>('/conversaciones');
    await expectLater(m.cliente.dio.post<dynamic>('/auth/token'), throwsA(isA<DioException>()));

    final protegida = m.red.peticiones.firstWhere((p) => p.path == '/conversaciones');
    final publica = m.red.peticiones.firstWhere((p) => p.path == '/auth/token');
    expect(protegida.headers['Authorization'], 'Bearer valido-2');
    expect(publica.headers.containsKey('Authorization'), isFalse);
    expect(protegida.headers[RequestIdInterceptor.encabezado], matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(protegida.uri.toString(), '$_base/conversaciones');
  });

  test('ante 401 renueva la sesión, guarda ambos tokens y reintenta', () async {
    final m = _montar(_Servidor());
    final r = await m.cliente.dio.get<Map<String, dynamic>>('/conversaciones');
    expect(r.data, {'ok': '/conversaciones'});
    expect(m.almacen.access, 'valido-2');
    expect(m.almacen.refresh, 'refresh-2');
    expect(m.red.llamadasA('/auth/refrescar'), 1);
  });

  test('varios 401 simultáneos provocan UNA sola renovación', () async {
    final m = _montar(_Servidor());
    final respuestas = await Future.wait([
      for (final ruta in ['/conversaciones', '/documentos', '/auth/me', '/conversaciones'])
        m.cliente.dio.get<Map<String, dynamic>>(ruta),
    ]);
    expect(respuestas.every((r) => r.statusCode == 200), isTrue);
    expect(m.red.llamadasA('/auth/refrescar'), 1);
  });

  test('si la renovación es rechazada (401): borra tokens, avisa y propaga 401', () async {
    final m = _montar(_Servidor(), refresh: 'robado');
    final avisos = <void>[];
    m.eventos.expiraciones.listen(avisos.add);
    await expectLater(
      ApiClient.ejecutar(() => m.cliente.dio.get<dynamic>('/conversaciones')),
      throwsA(isA<UnauthorizedException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(m.almacen.access, isNull);
    expect(m.almacen.refresh, isNull);
    expect(avisos, hasLength(1));
  });

  test('sin red durante la renovación conserva la sesión', () async {
    final servidor = _Servidor(
      refrescarResponde: () => throw DioException.connectionError(
        requestOptions: RequestOptions(path: '/auth/refrescar'),
        reason: 'sin red',
      ),
    );
    final m = _montar(servidor);
    await expectLater(m.cliente.dio.get<dynamic>('/conversaciones'), throwsA(isA<DioException>()));
    expect(m.almacen.refresh, 'refresh-1');
    expect(m.almacen.borrados, 0);
  });

  test('un 401 del login (credenciales) no intenta renovar', () async {
    final m = _montar(_Servidor());
    await expectLater(
      ApiClient.ejecutar(() => m.cliente.dio.post<dynamic>('/auth/token')),
      throwsA(isA<UnauthorizedException>().having((e) => e.detalle, 'detalle', 'Usuario o clave incorrectos.')),
    );
    expect(m.red.llamadasA('/auth/refrescar'), 0);
    expect(m.almacen.borrados, 0);
  });

  test('sin refresh token guardado: expira la sesión sin llamar a la API', () async {
    final m = _montar(_Servidor(), refresh: null);
    await expectLater(m.cliente.dio.get<dynamic>('/conversaciones'), throwsA(isA<DioException>()));
    expect(m.red.llamadasA('/auth/refrescar'), 0);
    expect(m.almacen.borrados, 1);
  });
}
