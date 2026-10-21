import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/network/lector_sse.dart';

Stream<List<int>> _trozos(String texto, int tamano) async* {
  final bytes = utf8.encode(texto);
  for (var i = 0; i < bytes.length; i += tamano) {
    yield bytes.sublist(i, i + tamano > bytes.length ? bytes.length : i + tamano);
  }
}

void main() {
  const cuerpo =
      'event: delta\ndata: {"texto": "No se podrá "}\n\n'
      ': comentario keep-alive\n\n'
      'event: delta\ndata: {"texto": "conducir con alcohol"}\n\n'
      'event: final\ndata: {"respuesta": "Sí, según el Art. 182"}\n\n';

  test('lee eventos aunque la red corte líneas y tildes a la mitad', () async {
    for (final tamano in [1, 3, 7, 1000]) {
      final eventos = await leerSse(_trozos(cuerpo, tamano)).toList();
      expect(eventos.map((e) => e.evento), ['delta', 'delta', 'final'], reason: 'trozos de $tamano bytes');
      expect(jsonDecode(eventos.first.datos)['texto'], 'No se podrá ');
    }
  });

  test('acepta Stream<Uint8List>, el tipo real que entrega dio', () async {
    final bytes = Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('event: delta\ndata: {"texto": "á"}\n\n')));
    expect((await leerSse(bytes).toList()).single.evento, 'delta');
  });

  test('un evento sin línea vacía final también se entrega', () async {
    final eventos = await leerSse(_trozos('event: error\ndata: {"codigo": "ocupado"}', 4)).toList();
    expect(eventos.single.evento, 'error');
  });
}
