import 'mensaje.dart';

/// Conversación (resumen) de `GET /conversaciones` y `POST /conversaciones`.
class Conversacion {
  const Conversacion({required this.id, required this.titulo, required this.creadaEn, required this.actualizadaEn});

  factory Conversacion.fromJson(Map<String, dynamic> json) => Conversacion(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    creadaEn: DateTime.parse(json['creada_en'] as String),
    actualizadaEn: DateTime.parse(json['actualizada_en'] as String),
  );

  final String id;

  /// "Nueva conversación" hasta la primera pregunta; luego se genera solo.
  final String titulo;
  final DateTime creadaEn;
  final DateTime actualizadaEn;

  Conversacion copyWith({String? titulo, DateTime? actualizadaEn}) => Conversacion(
    id: id,
    titulo: titulo ?? this.titulo,
    creadaEn: creadaEn,
    actualizadaEn: actualizadaEn ?? this.actualizadaEn,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'creada_en': creadaEn.toIso8601String(),
    'actualizada_en': actualizadaEn.toIso8601String(),
  };
}

/// Conversación con su historial (`GET /conversaciones/{id}`).
class ConversacionDetalle {
  const ConversacionDetalle({required this.conversacion, required this.mensajes});

  factory ConversacionDetalle.fromJson(Map<String, dynamic> json) => ConversacionDetalle(
    conversacion: Conversacion.fromJson(json),
    mensajes: (json['mensajes'] as List<dynamic>? ?? const [])
        .map((m) => Mensaje.fromJson(m as Map<String, dynamic>))
        .toList(),
  );

  final Conversacion conversacion;
  final List<Mensaje> mensajes;

  Map<String, dynamic> toJson() => {...conversacion.toJson(), 'mensajes': mensajes.map((m) => m.toJson()).toList()};
}
