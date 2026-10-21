import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lexiec/core/network/almacen_tokens.dart';

/// Adaptador HTTP en memoria: registra las peticiones y responde con [responder].
class AdaptadorFalso implements HttpClientAdapter {
  AdaptadorFalso(this.responder);

  Future<ResponseBody> Function(RequestOptions opciones) responder;
  final List<RequestOptions> peticiones = [];

  int llamadasA(String ruta) => peticiones.where((p) => p.path == ruta).length;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    peticiones.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody respuestaJson(int estado, Object? cuerpo, {Map<String, List<String>> encabezados = const {}}) =>
    ResponseBody.fromString(
      jsonEncode(cuerpo),
      estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...encabezados,
      },
    );

ResponseBody respuestaHtml(int estado, {Map<String, List<String>> encabezados = const {}}) => ResponseBody.fromString(
  '<html><body>$estado</body></html>',
  estado,
  headers: {
    Headers.contentTypeHeader: ['text/html'],
    ...encabezados,
  },
);

/// Almacén de tokens en memoria (las pruebas no tocan el almacenamiento seguro).
class AlmacenEnMemoria implements AlmacenTokens {
  AlmacenEnMemoria({this.access, this.refresh});

  String? access;
  String? refresh;
  int borrados = 0;

  @override
  Future<String?> leerAccess() async => access;

  @override
  Future<String?> leerRefresh() async => refresh;

  @override
  Future<void> guardar({required String access, String? refresh}) async {
    this.access = access;
    if (refresh != null) this.refresh = refresh;
  }

  @override
  Future<void> borrar() async {
    access = null;
    refresh = null;
    borrados++;
  }
}
