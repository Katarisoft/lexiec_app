/// Plan a la venta (`GET /planes`). El precio llega como texto decimal ("4.99"), no como número.
class PlanCatalogo {
  const PlanCatalogo({
    required this.codigo,
    required this.nombre,
    required this.consultas,
    required this.dias,
    required this.precioUsd,
    required this.descripcion,
  });

  factory PlanCatalogo.fromJson(Map<String, dynamic> json) => PlanCatalogo(
    codigo: json['codigo'] as String,
    nombre: json['nombre'] as String,
    consultas: json['consultas'] as int,
    dias: json['dias'] as int,
    precioUsd: json['precio_usd'].toString(),
    descripcion: json['descripcion'] as String,
  );

  final String codigo;
  final String nombre;
  final int consultas;
  final int dias;
  final String precioUsd;
  final String descripcion;

  /// "6 meses", "30 días".
  String get vigencia => dias % 30 == 0 && dias >= 60 ? '${dias ~/ 30} meses' : '$dias días';
}

/// Cómo se responde la próxima pregunta (guía de la API, § 6.11).
enum ModoPlan {
  cortesia,
  pagado,
  gratis,
  sinSaldo,
  desconocido;

  static ModoPlan desde(String? valor) => switch (valor) {
    'cortesia' => cortesia,
    'pagado' => pagado,
    'gratis' => gratis,
    'sin_saldo' => sinSaldo,
    _ => desconocido, // valores nuevos del servidor no rompen la app
  };
}

/// Lote de consultas pagado y vigente.
class LoteVigente {
  const LoteVigente({
    required this.plan,
    required this.nombre,
    required this.restantes,
    required this.total,
    required this.venceEn,
  });

  factory LoteVigente.fromJson(Map<String, dynamic> json) => LoteVigente(
    plan: json['plan'] as String,
    nombre: json['nombre'] as String,
    restantes: json['restantes'] as int,
    total: json['total'] as int,
    venceEn: DateTime.parse(json['vence_en'] as String),
  );

  final String plan;
  final String nombre;
  final int restantes;
  final int total;
  final DateTime venceEn;
}

/// Saldo de la cuenta (`GET /plan`).
class EstadoPlan {
  const EstadoPlan({
    required this.modo,
    required this.iaRapida,
    required this.consultasPagadas,
    required this.gratisLimite,
    required this.gratisRestantes,
    required this.gratisRenuevaEn,
    this.lotes = const [],
  });

  factory EstadoPlan.fromJson(Map<String, dynamic> json) => EstadoPlan(
    modo: ModoPlan.desde(json['modo'] as String?),
    iaRapida: json['ia_rapida'] as bool? ?? false,
    consultasPagadas: json['consultas_pagadas'] as int,
    gratisLimite: json['gratis_limite'] as int,
    gratisRestantes: json['gratis_restantes'] as int,
    gratisRenuevaEn: DateTime.parse(json['gratis_renueva_en'] as String),
    lotes: (json['lotes'] as List<dynamic>? ?? []).map((e) => LoteVigente.fromJson(e as Map<String, dynamic>)).toList(),
  );

  final ModoPlan modo;
  final bool iaRapida;
  final int consultasPagadas;
  final int gratisLimite;
  final int gratisRestantes;
  final DateTime gratisRenuevaEn;
  final List<LoteVigente> lotes;
}
