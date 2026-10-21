import 'package:dio/dio.dart';

import '../../core/errors/mapeador_errores.dart';
import '../../core/network/api_client.dart';
import '../../core/network/cancelacion.dart';
import '../../core/network/lector_sse.dart';
import '../models/evento_chat.dart';

/// `POST /conversaciones/{id}/mensajes/stream` (SSE).
class RemoteChatDatasource {
  RemoteChatDatasource(this._api);

  final ApiClient _api;

  /// Emite los eventos de la respuesta. Los errores HTTP previos al streaming
  /// (401, 404, 422, 429, 503…) se lanzan como `AppException`.
  Stream<EventoChat> preguntar(String conversacionId, String texto, {Cancelacion? cancelacion}) async* {
    final Response<ResponseBody> respuesta;
    try {
      respuesta = await _api.dio.post<ResponseBody>(
        '/conversaciones/$conversacionId/mensajes/stream',
        data: {'texto': texto},
        cancelToken: cancelacion?.token,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: ApiClient.tiempoIA,
          headers: {'Accept': 'text/event-stream'},
        ),
      );
    } on DioException catch (e) {
      throw await MapeadorErrores.desdeDio(e);
    }
    try {
      await for (final sse in leerSse(respuesta.data!.stream)) {
        final evento = EventoChat.desde(sse);
        if (evento != null) yield evento;
      }
    } on DioException catch (e) {
      throw await MapeadorErrores.desdeDio(e); // timeout o corte a mitad del streaming
    }
  }
}
