/// Norma indexada (`GET /documentos`).
class Documento {
  const Documento({required this.archivo, required this.paginas, required this.fragmentos, required this.indexadoEn});

  factory Documento.fromJson(Map<String, dynamic> json) => Documento(
    archivo: json['archivo'] as String,
    paginas: json['paginas'] as int,
    fragmentos: json['fragmentos'] as int,
    indexadoEn: DateTime.parse(json['indexado_en'] as String),
  );

  final String archivo;
  final int paginas;
  final int fragmentos;
  final DateTime indexadoEn;

  /// Nombre legible a partir del archivo: "Codigo-Organico-Integral-Penal2025.pdf" → "Codigo Organico Integral Penal2025".
  String get nombreVisible =>
      archivo.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '').replaceAll(RegExp(r'[-_]+'), ' ').trim();

  Map<String, dynamic> toJson() => {
    'archivo': archivo,
    'paginas': paginas,
    'fragmentos': fragmentos,
    'indexado_en': indexadoEn.toIso8601String(),
  };
}
