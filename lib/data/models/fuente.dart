/// Fragmento de documento usado en una respuesta (solo los citados).
class Fuente {
  const Fuente({
    required this.archivo,
    required this.pagina,
    required this.relevancia,
    required this.extracto,
    this.articulo,
  });

  factory Fuente.fromJson(Map<String, dynamic> json) => Fuente(
    archivo: json['archivo'] as String,
    pagina: json['pagina'] as int,
    articulo: json['articulo'] as String?,
    relevancia: (json['relevancia'] as num).toDouble(),
    extracto: json['extracto'] as String,
  );

  final String archivo;
  final int pagina;
  final String? articulo;

  /// Puntaje de búsqueda (0–1) solo para ordenar; no es confianza ni probabilidad.
  final double relevancia;
  final String extracto;

  Map<String, dynamic> toJson() => {
    'archivo': archivo,
    'pagina': pagina,
    'articulo': articulo,
    'relevancia': relevancia,
    'extracto': extracto,
  };
}
