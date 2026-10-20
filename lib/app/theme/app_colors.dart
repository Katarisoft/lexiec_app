import 'package:flutter/material.dart';

/// Paleta de LexiEC. Único lugar con colores literales de la app.
///
/// Identidad: azul marino institucional (confianza, ámbito jurídico) con un
/// acento ámbar cálido (guiño a la bandera, sin ser literal).
abstract final class AppColors {
  static const Color marino = Color(0xFF16306B);
  static const Color marinoClaro = Color(0xFF9DB6F2);
  static const Color ambar = Color(0xFFF5B301);
  static const Color sobreAmbar = Color(0xFF241A00);

  static const Color fondoClaro = Color(0xFFF5F7FC);
  static const Color superficieClara = Color(0xFFFFFFFF);
  static const Color fondoOscuro = Color(0xFF0C1222);
  static const Color superficieOscura = Color(0xFF151D33);

  /// Degradado de marca (pantalla de inicio, encabezados destacados).
  static const List<Color> degradadoMarca = [Color(0xFF0F2350), Color(0xFF23479B)];
}
