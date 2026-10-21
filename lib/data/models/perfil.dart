/// Perfil del usuario (`/auth/me`, `/auth/registro`).
class Perfil {
  const Perfil({required this.usuario, required this.creadoEn, this.correo, this.nombre});

  factory Perfil.fromJson(Map<String, dynamic> json) => Perfil(
    usuario: json['usuario'] as String,
    correo: json['correo'] as String?,
    nombre: json['nombre'] as String?,
    creadoEn: DateTime.parse(json['creado_en'] as String),
  );

  final String usuario;
  final String? correo;
  final String? nombre;
  final DateTime creadoEn;

  /// Nombre para mostrar: el nombre completo o, si no hay, el usuario.
  String get nombreVisible => (nombre?.trim().isNotEmpty ?? false) ? nombre!.trim() : usuario;

  Map<String, dynamic> toJson() => {
    'usuario': usuario,
    'correo': correo,
    'nombre': nombre,
    'creado_en': creadoEn.toIso8601String(),
  };
}
