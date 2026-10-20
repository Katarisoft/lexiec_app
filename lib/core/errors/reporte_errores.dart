import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Manejo global de errores no capturados: la app nunca muestra la pantalla
/// roja/gris de Flutter ni se cierra por un error inesperado.
///
/// En los registros solo se escribe el tipo de error (y el detalle en modo
/// desarrollo): nunca tokens ni contenido de las consultas.
abstract final class ReporteErrores {
  static void instalar() {
    FlutterError.onError = (detalles) {
      if (kDebugMode) {
        FlutterError.presentError(detalles);
      } else {
        debugPrint('Error de interfaz: ${detalles.exception.runtimeType}');
      }
    };

    PlatformDispatcher.instance.onError = (error, pila) {
      debugPrint('Error no controlado: ${kDebugMode ? error : error.runtimeType}');
      return true; // manejado: evita el cierre de la app
    };

    ErrorWidget.builder = (detalles) => const ErrorDeSeccion();
  }
}

/// Reemplazo amable del widget de error de Flutter dentro de una sección.
class ErrorDeSeccion extends StatelessWidget {
  const ErrorDeSeccion({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Material(
      color: tema.colorScheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.build_circle_outlined, size: 40, color: tema.colorScheme.outline),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Esta sección no se pudo mostrar.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
