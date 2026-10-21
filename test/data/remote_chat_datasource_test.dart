import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/core/network/api_client.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/data/datasources/remote_chat_datasource.dart';
import 'package:lexiec/data/models/evento_chat.dart';

import '../helpers/red_falsa.dart';

const _final = {
  'respuesta': 'No se podrá conducir con alcohol sobre lo permitido.',
  'citas': [
    {'archivo': 'ley.pdf', 'pagina': 41, 'articulo': '182', 'texto': 'No se podrá conducir…'},
  ],
  'fuentes': [],
  'duracion_ms': 39410,
  'conversacion_id': 'c1',
  'titulo': '¿Se puede conducir después de beber alcohol?',
  'mensaje_id': 16,
};

ResponseBody _sse(String cuerpo) => ResponseBody(
  Stream.fromIterable(utf8.encode(cuerpo).map((b) => Uint8List.fromList([b]))), // byte a byte
  200,
  headers: {
    Headers.contentTypeHeader: ['text/event-stream'],
  },
);

RemoteChatDatasource _datasource(Future<ResponseBody> Function(RequestOptions) responder, [AdaptadorFalso? red]) {
  final adaptador = red ?? AdaptadorFalso(responder);
  return RemoteChatDatasource(
    ApiClient(
      almacen: AlmacenEnMemoria(access: 'a'),
      eventos: EventosSesion(),
      baseUrl: 'http://api.test/api/v1',
      adaptador: adaptador,
    ),
  );
}

void main() {
  test('streaming: deltas provisionales y respuesta final verificada', () async {
    final red = AdaptadorFalso(
      (_) async => _sse(
        'event: delta\ndata: {"texto": "No se podrá "}\n\n'
        'event: delta\ndata: {"texto": "conducir…"}\n\n'
        'event: final\ndata: ${jsonEncode(_final)}\n\n',
      ),
    );
    final eventos = await _datasource(
      (_) async => throw UnimplementedError(),
      red,
    ).preguntar('c1', '¿Se puede?').toList();
    expect(eventos.whereType<EventoDelta>().map((e) => e.texto).join(), 'No se podrá conducir…');
    final fin = eventos.last as EventoFinal;
    expect(fin.respuesta.citas.single.referencia, 'Art. 182 · pág. 41');
    final peticion = red.peticiones.single;
    expect(peticion.path, '/conversaciones/c1/mensajes/stream');
    expect(peticion.headers['Accept'], 'text/event-stream');
    expect(peticion.data, {'texto': '¿Se puede?'});
  });

  test('evento error del servidor', () async {
    final eventos = await _datasource(
      (_) async => _sse('event: error\ndata: {"detalle": "El servicio está ocupado.", "codigo": "ocupado"}\n\n'),
    ).preguntar('c1', 'pregunta').toList();
    expect((eventos.single as EventoError).codigo, 'ocupado');
  });

  test('503 antes del streaming: ServiceBusyException con Retry-After', () async {
    final ds = _datasource(
      (_) async => respuestaJson(
        503,
        {'detail': '…', 'codigo': 'ocupado'},
        encabezados: {
          'retry-after': ['12'],
        },
      ),
    );
    await expectLater(
      ds.preguntar('c1', 'pregunta').toList(),
      throwsA(isA<ServiceBusyException>().having((e) => e.reintentarEn, 'reintentarEn', const Duration(seconds: 12))),
    );
  });

  test('404 antes del streaming: NotFoundException', () async {
    final ds = _datasource((_) async => respuestaJson(404, {'detail': 'Conversación no encontrada.'}));
    await expectLater(ds.preguntar('x', 'pregunta').toList(), throwsA(isA<NotFoundException>()));
  });
}
