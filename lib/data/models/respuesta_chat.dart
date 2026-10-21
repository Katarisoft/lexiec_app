import 'cita.dart';
import 'fuente.dart';

/// Respuesta del asistente (`POST /conversaciones/{id}/mensajes` o evento SSE `final`).
class RespuestaChat {
  const RespuestaChat({
    required this.respuesta,
    required this.citas,
    required this.fuentes,
    required this.duracionMs,
    required this.conversacionId,
    required this.titulo,
    required this.mensajeId,
  });

  factory RespuestaChat.fromJson(Map<String, dynamic> json) => RespuestaChat(
    respuesta: json['respuesta'] as String,
    citas: (json['citas'] as List<dynamic>? ?? const []).map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList(),
    fuentes: (json['fuentes'] as List<dynamic>? ?? const [])
        .map((e) => Fuente.fromJson(e as Map<String, dynamic>))
        .toList(),
    duracionMs: json['duracion_ms'] as int,
    conversacionId: json['conversacion_id'] as String,
    titulo: json['titulo'] as String,
    mensajeId: json['mensaje_id'] as int,
  );

  /// Texto exacto que devuelve la API cuando los PDFs no contienen la respuesta (guía § 4).
  static const String textoSinInformacion = 'No encontré información suficiente en los documentos disponibles.';

  final String respuesta;
  final List<Cita> citas;
  final List<Fuente> fuentes;
  final int duracionMs;
  final String conversacionId;
  final String titulo;
  final int mensajeId;

  /// Sin citas = respuesta "sin información" (guía: mostrar un estado especial).
  bool get sinInformacion => citas.isEmpty;
}
