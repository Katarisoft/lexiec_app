import 'package:flutter/widgets.dart';

/// Espaciados en múltiplos de 4 dp.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Margen lateral estándar de las pantallas.
  static const EdgeInsets pantalla = EdgeInsets.symmetric(horizontal: md);
}

/// Radios de borde.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

/// Tamaño mínimo de área táctil (accesibilidad).
abstract final class AppSizes {
  static const double toqueMinimo = 48;
  static const double botonAlto = 52;
  static const double anchoMaximoContenido = 560;
}
