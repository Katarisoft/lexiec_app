import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lexiec/data/datasources/local_preferencias_datasource.dart';

void main() {
  late Directory carpeta;

  setUp(() async {
    carpeta = await Directory.systemTemp.createTemp('lexiec_hive_');
    Hive.init(carpeta.path);
  });

  tearDown(() async {
    await Hive.close();
    await carpeta.delete(recursive: true);
  });

  test('la bienvenida vista persiste al reabrir la caja (simula reiniciar la app)', () async {
    final prefs = LocalPreferenciasDatasource();
    expect(await prefs.bienvenidaVista(), isFalse);
    await prefs.marcarBienvenidaVista();
    await Hive.close(); // "matar" la app
    Hive.init(carpeta.path);
    expect(await LocalPreferenciasDatasource().bienvenidaVista(), isTrue);
  });
}
