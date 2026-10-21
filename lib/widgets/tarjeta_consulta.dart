import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';
import '../data/models/conversacion.dart';
import 'formato_fecha.dart';

/// Elemento de "Mis consultas": se abre al tocarlo y se elimina deslizándolo
/// hacia la izquierda o desde el menú (alternativa accesible al gesto).
class TarjetaConsulta extends StatelessWidget {
  const TarjetaConsulta({super.key, required this.conversacion, required this.alAbrir, required this.alEliminar});

  final Conversacion conversacion;
  final VoidCallback alAbrir;
  final VoidCallback alEliminar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Dismissible(
      key: ValueKey(conversacion.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => alEliminar(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(color: esquema.errorContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Eliminar',
              style: TextStyle(color: esquema.onErrorContainer, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.delete_outline, color: esquema.onErrorContainer),
          ],
        ),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alAbrir,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, AppSpacing.md),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: esquema.primaryContainer,
                  foregroundColor: esquema.onPrimaryContainer,
                  child: const Icon(Icons.chat_bubble_outline, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversacion.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        FormatoFecha.relativa(conversacion.actualizadaEn),
                        style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  onSelected: (_) => alEliminar(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'eliminar',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Eliminar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
