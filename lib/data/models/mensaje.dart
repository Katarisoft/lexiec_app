import 'cita.dart';
import 'fuente.dart';

enum RolMensaje {
  usuario,
  asistente;

  static RolMensaje desde(String valor) => valor == 'usuario' ? usuario : asistente;
}

/// Mensaje de una conversación (`GET /conversaciones/{id}`).
class Mensaje {
  const Mensaje({
    required this.id,
    required this.rol,
    required this.contenido,
    required this.creadoEn,
    this.citas = const [],
    this.fuentes = const [],
  });

  factory Mensaje.fromJson(Map<String, dynamic> json) => Mensaje(
    id: json['id'] as int,
    rol: RolMensaje.desde(json['rol'] as String),
    contenido: json['contenido'] as String,
    citas: _lista(json['citas'], Cita.fromJson),
    fuentes: _lista(json['fuentes'], Fuente.fromJson),
    creadoEn: DateTime.parse(json['creado_en'] as String),
  );

  final int id;
  final RolMensaje rol;
  final String contenido;
  final List<Cita> citas;
  final List<Fuente> fuentes;
  final DateTime creadoEn;

  bool get esDelUsuario => rol == RolMensaje.usuario;

  Map<String, dynamic> toJson() => {
    'id': id,
    'rol': rol.name,
    'contenido': contenido,
    'citas': citas.map((c) => c.toJson()).toList(),
    'fuentes': fuentes.map((f) => f.toJson()).toList(),
    'creado_en': creadoEn.toIso8601String(),
  };
}

List<T> _lista<T>(Object? datos, T Function(Map<String, dynamic>) desde) =>
    (datos as List<dynamic>? ?? const []).map((e) => desde(e as Map<String, dynamic>)).toList();
