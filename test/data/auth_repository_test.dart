import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/datasources/local_preferencias_datasource.dart';
import 'package:lexiec/data/datasources/remote_auth_datasource.dart';
import 'package:lexiec/data/models/tokens_sesion.dart';
import 'package:lexiec/data/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';
import '../helpers/red_falsa.dart';

class _RemotoMock extends Mock implements RemoteAuthDatasource {}

class _PreferenciasMock extends Mock implements LocalPreferenciasDatasource {}

void main() {
  late _RemotoMock remoto;
  late AlmacenEnMemoria tokens;
  late AuthRepository repo;

  setUp(() {
    remoto = _RemotoMock();
    tokens = AlmacenEnMemoria();
    repo = AuthRepository(remoto: remoto, tokens: tokens, preferencias: _PreferenciasMock());
    when(
      () => remoto.iniciarSesion(any(), any()),
    ).thenAnswer((_) async => const TokensSesion(accessToken: 'acc', expiresIn: 900, refreshToken: 'ref'));
    when(remoto.perfil).thenAnswer((_) async => perfilDemo);
  });

  test('iniciar sesión guarda ambos tokens y devuelve el perfil', () async {
    final perfil = await repo.iniciarSesion('  maria.perez ', 'clave');
    expect(perfil.usuario, 'maria.perez');
    expect(tokens.access, 'acc');
    expect(tokens.refresh, 'ref');
    verify(() => remoto.iniciarSesion('maria.perez', 'clave')).called(1);
  });

  test('registrar crea la cuenta y luego inicia sesión', () async {
    when(
      () => remoto.registrar(
        usuario: any(named: 'usuario'),
        clave: any(named: 'clave'),
        codigoInvitacion: any(named: 'codigoInvitacion'),
        correo: any(named: 'correo'),
        nombre: any(named: 'nombre'),
      ),
    ).thenAnswer((_) async => perfilDemo);
    await repo.registrar(usuario: 'maria.perez', clave: 'clave larga 123', codigoInvitacion: ' COD ');
    verify(() => remoto.registrar(usuario: 'maria.perez', clave: 'clave larga 123', codigoInvitacion: 'COD')).called(1);
    expect(tokens.access, 'acc');
  });

  test('cerrar sesión borra los tokens aunque el servidor no responda', () async {
    tokens.access = 'acc';
    tokens.refresh = 'ref';
    when(() => remoto.cerrarSesion(any())).thenThrow(const NetworkException());
    await repo.cerrarSesion();
    expect(tokens.access, isNull);
    expect(tokens.refresh, isNull);
    verify(() => remoto.cerrarSesion('ref')).called(1);
  });
}
