import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/normas_controller.dart';
import '../../controllers/view_status.dart';
import '../../widgets/estado_views.dart';

/// Normas sobre las que responde el asistente.
class NormasScreen extends GetView<NormasController> {
  const NormasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Normas disponibles')),
      body: Obx(
        () => switch (controller.estado.value) {
          ViewStatus.loading => const EsqueletoLista(elementos: 4),
          ViewStatus.error => ErrorView(mensaje: controller.mensajeError.value, onReintentar: controller.cargar),
          ViewStatus.empty => const EmptyView(
            icono: Icons.menu_book_outlined,
            titulo: 'Aún no hay normas cargadas',
            mensaje: 'Cuando la administración cargue documentos, aparecerán aquí.',
          ),
          ViewStatus.success => RefreshIndicator(
            onRefresh: controller.cargar,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'LexiEC responde únicamente con el contenido de estas ${controller.documentos.length} normas.',
                  style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final d in controller.documentos)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        leading: CircleAvatar(
                          backgroundColor: esquema.primaryContainer,
                          foregroundColor: esquema.onPrimaryContainer,
                          child: const Icon(Icons.description_outlined),
                        ),
                        title: Text(d.nombreVisible, style: tema.textTheme.titleMedium),
                        subtitle: Text(
                          '${d.paginas} páginas · actualizada el ${DateFormat.yMMMd('es').format(d.indexadoEn.toLocal())}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        },
      ),
    );
  }
}
