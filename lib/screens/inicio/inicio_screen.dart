import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../widgets/lexiec_marca.dart';

/// Pantalla de arranque con la marca. En la Fase 2 restaura la sesión y
/// navega al login o a "Mis consultas".
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.degradadoMarca,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LexiecMarca(tamano: 88, sobreFondoOscuro: true),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'La ley ecuatoriana, explicada con sus fuentes',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyLarge?.copyWith(color: tema.colorScheme.onPrimary.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: tema.colorScheme.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
