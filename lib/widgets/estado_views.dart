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

/// Esqueleto de una lista mientras carga (evita una pantalla vacía).
class EsqueletoLista extends StatelessWidget {
  const EsqueletoLista({super.key, this.elementos = 6});

  final int elementos;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget barra(double ancho, double alto) => Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppRadius.sm)),
    );
    return Semantics(
      label: 'Cargando',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: elementos,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      barra(double.infinity, 14),
                      const SizedBox(height: AppSpacing.sm),
                      barra(90, 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Franja que avisa que se muestra el historial guardado porque no hay conexión.
class AvisoSinConexion extends StatelessWidget {
  const AvisoSinConexion({super.key, required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 20, color: esquema.onTertiaryContainer),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Sin conexión: estás viendo tu historial guardado.',
                style: TextStyle(color: esquema.onTertiaryContainer),
              ),
            ),
            TextButton(onPressed: alReintentar, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
