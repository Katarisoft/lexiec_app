import 'package:flutter/material.dart';

/// Paleta de LexiEC. Único lugar con colores literales de la app.
///
/// Identidad: azul marino institucional (confianza, ámbito jurídico) con un
/// acento ámbar cálido (guiño a la bandera, sin ser literal).
/// Todos los pares texto/fondo cumplen contraste WCAG AA (≥ 4.5:1), verificado
/// en `test/app/contraste_test.dart`.
abstract final class AppColors {
  static const Color marino = Color(0xFF16306B);
  static const Color marinoClaro = Color(0xFF9DB6F2);
  static const Color ambar = Color(0xFFF5B301);
  static const Color sobreAmbar = Color(0xFF241A00);

  /// Ámbar oscurecido para TEXTO sobre fondos claros (el ámbar puro no se lee sobre blanco).
  static const Color ambarTexto = Color(0xFF7A5200);

  static const Color fondoClaro = Color(0xFFF5F7FC);
  static const Color superficieClara = Color(0xFFFFFFFF);
  static const Color textoClaro = Color(0xFF141B2D);
  static const Color textoSecundarioClaro = Color(0xFF4A5368);

  static const Color fondoOscuro = Color(0xFF0C1222);
  static const Color superficieOscura = Color(0xFF151D33);
  static const Color textoOscuro = Color(0xFFE8ECF6);
  static const Color textoSecundarioOscuro = Color(0xFFB4BDD2);

  /// Degradado de marca: siempre oscuro, en ambos temas.
  static const List<Color> degradadoMarca = [Color(0xFF0F2350), Color(0xFF23479B)];

  /// Texto sobre el degradado de marca (fijo: no depende del tema claro/oscuro).
  static const Color textoSobreMarca = Color(0xFFFFFFFF);
  static const Color textoSobreMarcaSuave = Color(0xFFD6E0F7);
}

/// Colores de marca que dependen del tema y no existen en [ColorScheme].
/// Uso: `Theme.of(context).extension<ColoresMarca>()!`.
@immutable
class ColoresMarca extends ThemeExtension<ColoresMarca> {
  const ColoresMarca({
    required this.acentoTexto,
    required this.textoSobreMarca,
    required this.textoSobreMarcaSuave,
    required this.degradado,
  });

  /// Acento ámbar legible como texto sobre la superficie del tema.
  final Color acentoTexto;
  final Color textoSobreMarca;
  final Color textoSobreMarcaSuave;
  final List<Color> degradado;

  static const ColoresMarca claro = ColoresMarca(
    acentoTexto: AppColors.ambarTexto,
    textoSobreMarca: AppColors.textoSobreMarca,
    textoSobreMarcaSuave: AppColors.textoSobreMarcaSuave,
    degradado: AppColors.degradadoMarca,
  );

  static const ColoresMarca oscuro = ColoresMarca(
    acentoTexto: AppColors.ambar,
    textoSobreMarca: AppColors.textoSobreMarca,
    textoSobreMarcaSuave: AppColors.textoSobreMarcaSuave,
    degradado: AppColors.degradadoMarca,
  );

  static ColoresMarca de(BuildContext context) => Theme.of(context).extension<ColoresMarca>()!;

  @override
  ColoresMarca copyWith({
    Color? acentoTexto,
    Color? textoSobreMarca,
    Color? textoSobreMarcaSuave,
    List<Color>? degradado,
  }) => ColoresMarca(
    acentoTexto: acentoTexto ?? this.acentoTexto,
    textoSobreMarca: textoSobreMarca ?? this.textoSobreMarca,
    textoSobreMarcaSuave: textoSobreMarcaSuave ?? this.textoSobreMarcaSuave,
    degradado: degradado ?? this.degradado,
  );

  @override
  ColoresMarca lerp(ColoresMarca? otro, double t) {
    if (otro == null) return this;
    return ColoresMarca(
      acentoTexto: Color.lerp(acentoTexto, otro.acentoTexto, t)!,
      textoSobreMarca: Color.lerp(textoSobreMarca, otro.textoSobreMarca, t)!,
      textoSobreMarcaSuave: Color.lerp(textoSobreMarcaSuave, otro.textoSobreMarcaSuave, t)!,
      degradado: t < 0.5 ? degradado : otro.degradado,
    );
  }
}
