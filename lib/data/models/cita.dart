/// Texto literal del PDF que respalda una respuesta.
class Cita {
  const Cita({required this.archivo, required this.pagina, required this.texto, this.articulo});

  factory Cita.fromJson(Map<String, dynamic> json) => Cita(
    archivo: json['archivo'] as String,
    pagina: json['pagina'] as int,
    articulo: json['articulo'] as String?,
    texto: json['texto'] as String,
  );

  final String archivo;
  final int pagina;

  /// Número de artículo ("36", "4.1", "10 bis") o null si el documento no tiene articulado.
  final String? articulo;
  final String texto;

  /// Referencia corta para mostrar: "Art. 36 · pág. 18" o "pág. 18".
  String get referencia => articulo != null ? 'Art. $articulo · pág. $pagina' : 'pág. $pagina';

  Map<String, dynamic> toJson() => {'archivo': archivo, 'pagina': pagina, 'articulo': articulo, 'texto': texto};
}
