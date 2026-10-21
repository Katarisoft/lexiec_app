import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lexiec/data/datasources/local_conversaciones_datasource.dart';
import 'package:lexiec/data/models/conversacion.dart';

class _ClaveFija implements ClaveCache {
  @override
  Future<List<int>> obtener() async => List<int>.generate(32, (i) => i);
}

Conversacion _conv(String id, String titulo) => Conversacion(
  id: id,
  titulo: titulo,
  creadaEn: DateTime.utc(2026, 10, 20),
  actualizadaEn: DateTime.utc(2026, 10, 20, 12),
);

void main() {
  late Directory carpeta;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('lexiec_conv_');
    Hive.init(carpeta.path);
  });

  tearDown(() async {
    await Hive.close();
    await carpeta.delete(recursive: true);
  });

  test('el historial sobrevive al cierre de la app y se guarda cifrado en disco', () async {
    final local = LocalConversacionesDatasource(_ClaveFija());
    await local.asignarUsuario('maria.perez');
    await local.guardarLista([_conv('a', 'Derechos de adultos mayores')]);
    await local.guardarDetalle(
      ConversacionDetalle(conversacion: _conv('a', 'Derechos de adultos mayores'), mensajes: const []),
    );
    await Hive.close(); // cierre completo

    final bytes = await File('${carpeta.path}/${LocalConversacionesDatasource.caja}.hive').readAsBytes();
    expect(String.fromCharCodes(bytes).contains('adultos mayores'), isFalse, reason: 'debe estar cifrado');

    Hive.init(carpeta.path);
    final reabierto = LocalConversacionesDatasource(_ClaveFija());
    await reabierto.asignarUsuario('maria.perez');
    expect((await reabierto.leerLista())!.single.titulo, 'Derechos de adultos mayores');
    expect((await reabierto.leerDetalle('a'))!.conversacion.id, 'a');
  });

  test('otra cuenta en el mismo dispositivo no ve el historial anterior', () async {
    final local = LocalConversacionesDatasource(_ClaveFija());
    await local.asignarUsuario('maria.perez');
    await local.guardarLista([_conv('a', 'Privada')]);
    await local.asignarUsuario('juan');
    expect(await local.leerLista(), isNull);
  });

  test('eliminar quita la consulta de la lista y su detalle; vaciar borra todo', () async {
    final local = LocalConversacionesDatasource(_ClaveFija());
    await local.guardarLista([_conv('a', 'A'), _conv('b', 'B')]);
    await local.guardarDetalle(ConversacionDetalle(conversacion: _conv('a', 'A'), mensajes: const []));
    await local.eliminar('a');
    expect((await local.leerLista())!.map((c) => c.id), ['b']);
    expect(await local.leerDetalle('a'), isNull);
    await local.vaciar();
    expect(await local.leerLista(), isNull);
  });
}
