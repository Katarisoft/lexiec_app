import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/datasources/local_conversaciones_datasource.dart';
import 'package:lexiec/data/datasources/remote_conversaciones_datasource.dart';
import 'package:lexiec/data/models/conversacion.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:mocktail/mocktail.dart';

class _RemotoMock extends Mock implements RemoteConversacionesDatasource {}

class _LocalMock extends Mock implements LocalConversacionesDatasource {}

Conversacion _conv(String id) =>
    Conversacion(id: id, titulo: 'C$id', creadaEn: DateTime.utc(2026), actualizadaEn: DateTime.utc(2026));

void main() {
  late _RemotoMock remoto;
  late _LocalMock local;
  late ConversacionesRepository repo;

  setUpAll(() => registerFallbackValue(<Conversacion>[]));

  setUp(() {
    remoto = _RemotoMock();
    local = _LocalMock();
    repo = ConversacionesRepository(remoto: remoto, local: local);
    when(() => local.guardarLista(any())).thenAnswer((_) async {});
    when(() => local.eliminar(any())).thenAnswer((_) async {});
  });

  test('en línea: trae de la API y guarda en el historial local', () async {
    final items = List.generate(20, (i) => _conv('$i'));
    when(() => remoto.listar(limite: 20)).thenAnswer((_) async => items);
    final pagina = await repo.primeraPagina();
    expect(pagina.desdeCache, isFalse);
    expect(pagina.hayMas, isTrue);
    verify(() => local.guardarLista(items)).called(1);
  });

  test('sin conexión: devuelve el historial local marcado como tal', () async {
    when(() => remoto.listar(limite: 20)).thenThrow(const NetworkException());
    when(local.leerLista).thenAnswer((_) async => [_conv('a')]);
    final pagina = await repo.primeraPagina();
    expect(pagina.desdeCache, isTrue);
    expect(pagina.items.single.id, 'a');
  });

  test('sin conexión y sin historial: propaga el error (la pantalla muestra Reintentar)', () async {
    when(() => remoto.listar(limite: 20)).thenThrow(const NetworkException());
    when(local.leerLista).thenAnswer((_) async => null);
    expect(repo.primeraPagina(), throwsA(isA<NetworkException>()));
  });

  test('un error del servidor no se oculta con datos viejos', () async {
    when(() => remoto.listar(limite: 20)).thenThrow(const ServerException(statusCode: 500));
    expect(repo.primeraPagina(), throwsA(isA<ServerException>()));
    verifyNever(local.leerLista);
  });

  test('la página siguiente no duplica elementos', () async {
    when(() => remoto.listar(limite: 20, desplazamiento: 2)).thenAnswer((_) async => [_conv('b'), _conv('c')]);
    final pagina = await repo.siguientePagina([_conv('a'), _conv('b')]);
    expect(pagina.items.map((c) => c.id), ['a', 'b', 'c']);
  });

  test('eliminar tolera 404 (ya no existía) y limpia el historial local', () async {
    when(() => remoto.eliminar('x')).thenThrow(const NotFoundException());
    await repo.eliminar('x');
    verify(() => local.eliminar('x')).called(1);
  });

  test('eliminar con otro error no toca el historial local', () async {
    when(() => remoto.eliminar('x')).thenThrow(const NetworkException());
    await expectLater(repo.eliminar('x'), throwsA(isA<NetworkException>()));
    verifyNever(() => local.eliminar('x'));
  });
}
