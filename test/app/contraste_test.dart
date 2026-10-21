import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/app/theme/app_colors.dart';
import 'package:lexiec/app/theme/app_theme.dart';

/// Relación de contraste WCAG 2.1 entre dos colores opacos.
double contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  const minimoTexto = 4.5; // WCAG AA, texto normal

  for (final (nombre, tema) in [('claro', AppTheme.claro()), ('oscuro', AppTheme.oscuro())]) {
    final e = tema.colorScheme;
    final marca = tema.extension<ColoresMarca>()!;
    final pares = <String, (Color, Color)>{
      'texto / superficie': (e.onSurface, e.surface),
      'texto / fondo': (e.onSurface, tema.scaffoldBackgroundColor),
      'texto secundario / superficie': (e.onSurfaceVariant, e.surface),
      'texto secundario / fondo': (e.onSurfaceVariant, tema.scaffoldBackgroundColor),
      'sobre primario / primario': (e.onPrimary, e.primary),
      'sobre secundario / secundario': (e.onSecondary, e.secondary),
      'acento como texto / superficie': (marca.acentoTexto, e.surface),
      'acento como texto / fondo': (marca.acentoTexto, tema.scaffoldBackgroundColor),
      'error / superficie': (e.error, e.surface),
      'primario como texto / fondo': (e.primary, tema.scaffoldBackgroundColor),
      for (final c in marca.degradado) ...{
        'texto marca / degradado $c': (marca.textoSobreMarca, c),
        'texto marca suave / degradado $c': (marca.textoSobreMarcaSuave, c),
        'ámbar / degradado $c': (e.secondary, c),
      },
    };
    pares.forEach((par, colores) {
      test('tema $nombre: $par ≥ $minimoTexto:1', () {
        final r = contraste(colores.$1, colores.$2);
        expect(r, greaterThanOrEqualTo(minimoTexto), reason: '${r.toStringAsFixed(2)}:1');
      });
    });
  }
}
