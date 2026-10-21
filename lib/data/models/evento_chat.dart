import 'dart:convert';

import '../../core/network/lector_sse.dart';
import 'respuesta_chat.dart';

/// Eventos del streaming de una respuesta (guía de la API, § 6.6).
sealed class EventoChat {
  const EventoChat();

  /// null para eventos desconocidos (se ignoran: compatibilidad con versiones futuras).
  static EventoChat? desde(EventoSse sse) {
    final json = jsonDecode(sse.datos) as Map<String, dynamic>;
    return switch (sse.evento) {
      'delta' => EventoDelta(json['texto'] as String? ?? ''),
      'final' => EventoFinal(RespuestaChat.fromJson(json)),
      'error' => EventoError(
        detalle: json['detalle'] as String? ?? 'No fue posible procesar la consulta.',
        codigo: json['codigo'] as String? ?? 'interno',
      ),
      _ => null,
    };
  }
}

/// Texto provisional que se va generando (puede ser reemplazado por el final).
final class EventoDelta extends EventoChat {
  const EventoDelta(this.texto);

  final String texto;
}

/// Respuesta verificada: REEMPLAZA al texto provisional.
final class EventoFinal extends EventoChat {
  const EventoFinal(this.respuesta);

  final RespuestaChat respuesta;
}

/// Error durante la generación: `codigo` = "ocupado" | "timeout" | "interno". El turno no se guardó.
final class EventoError extends EventoChat {
  const EventoError({required this.detalle, required this.codigo});

  final String detalle;
  final String codigo;
}
