import '../../core/network/cancelacion.dart';
import '../datasources/local_conversaciones_datasource.dart';
import '../datasources/remote_chat_datasource.dart';
import '../models/conversacion.dart';
import '../models/evento_chat.dart';

/// Preguntas al asistente y actualización del historial local tras cada respuesta.
class ChatRepository {
  ChatRepository({required this._remoto, required this._local});

  final RemoteChatDatasource _remoto;
  final LocalConversacionesDatasource _local;

  Stream<EventoChat> preguntar(String conversacionId, String texto, {Cancelacion? cancelacion}) =>
      _remoto.preguntar(conversacionId, texto.trim(), cancelacion: cancelacion);

  /// Guarda el historial actualizado y sube la consulta al inicio de la lista local.
  Future<void> guardarHistorial(ConversacionDetalle detalle) async {
    await _local.guardarDetalle(detalle);
    final lista = await _local.leerLista() ?? const <Conversacion>[];
    await _local.guardarLista([detalle.conversacion, ...lista.where((c) => c.id != detalle.conversacion.id)]);
  }
}
