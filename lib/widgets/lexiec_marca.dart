import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';

/// Logotipo de LexiEC: balanza dentro de un sello y el nombre.
class LexiecMarca extends StatelessWidget {
  const LexiecMarca({super.key, this.tamano = 72, this.sobreFondoOscuro = false});

  final double tamano;
  final bool sobreFondoOscuro;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colorTexto = sobreFondoOscuro ? esquema.onPrimary : esquema.onSurface;
    return Semantics(
      label: 'LexiEC',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tamano,
              height: tamano,
              decoration: BoxDecoration(color: esquema.secondary, borderRadius: BorderRadius.circular(tamano * 0.3)),
              child: Icon(Icons.balance, size: tamano * 0.55, color: esquema.onSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Lexi'),
                  TextSpan(
                    text: 'EC',
                    style: TextStyle(color: esquema.secondary),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: colorTexto),
            ),
          ],
        ),
      ),
    );
  }
}
