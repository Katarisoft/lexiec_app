import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';

/// Estado de carga: indicador y mensaje opcional.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.mensaje});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Semantics(
        liveRegion: true,
        label: mensaje ?? 'Cargando',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (mensaje != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                mensaje!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vacío: explica por qué no hay datos y sugiere una acción.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.textoAccion,
    this.onAccion,
  });

  final String titulo;
  final String mensaje;
  final IconData icono;
  final String? textoAccion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: icono,
      colorIcono: Theme.of(context).colorScheme.primary,
      titulo: titulo,
      mensaje: mensaje,
      accion: textoAccion != null && onAccion != null
          ? FilledButton.tonalIcon(onPressed: onAccion, icon: const Icon(Icons.add), label: Text(textoAccion!))
          : null,
    );
  }
}

/// Estado de error: mensaje comprensible y botón Reintentar.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.mensaje,
    required this.onReintentar,
    this.titulo = 'Algo no salió bien',
    this.icono = Icons.cloud_off_outlined,
  });

  final String titulo;
  final String mensaje;
  final IconData icono;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return _EstadoBase(
      icono: icono,
      colorIcono: Theme.of(context).colorScheme.error,
      titulo: titulo,
      mensaje: mensaje,
      accion: OutlinedButton.icon(
        onPressed: onReintentar,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      ),
    );
  }
}

class _EstadoBase extends StatelessWidget {
  const _EstadoBase({
    required this.icono,
    required this.colorIcono,
    required this.titulo,
    required this.mensaje,
    this.accion,
  });

  final IconData icono;
  final Color colorIcono;
  final String titulo;
  final String mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoContenido),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: colorIcono.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Icon(icono, size: 40, color: colorIcono),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(titulo, textAlign: TextAlign.center, style: tema.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
              if (accion != null) ...[const SizedBox(height: AppSpacing.lg), SizedBox(width: 220, child: accion)],
            ],
          ),
        ),
      ),
    );
  }
}
