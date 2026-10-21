import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/consulta_controller.dart';
import '../../controllers/view_status.dart';
import '../../widgets/burbuja_mensaje.dart';
import '../../widgets/estado_views.dart';

/// Detalle de una consulta: preguntas y respuestas con sus fuentes.
class ConsultaScreen extends GetView<ConsultaController> {
  const ConsultaScreen({super.key});

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Eliminar esta consulta?'),
        content: const Text('Se borrarán todas sus preguntas y respuestas. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmar ?? false) await controller.eliminar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.titulo, maxLines: 1, overflow: TextOverflow.ellipsis)),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            onSelected: (_) => _confirmarEliminacion(context),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'eliminar',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Eliminar consulta'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(
        () => switch (controller.estado.value) {
          ViewStatus.loading => const LoadingView(mensaje: 'Cargando consulta…'),
          ViewStatus.error => ErrorView(mensaje: controller.mensajeError.value, onReintentar: controller.cargar),
          ViewStatus.empty => const EmptyView(
            icono: Icons.edit_note,
            titulo: 'Consulta sin preguntas',
            mensaje: 'Esta consulta aún no tiene preguntas.',
          ),
          ViewStatus.success => Column(
            children: [
              if (controller.sinConexion.value) AvisoSinConexion(alReintentar: controller.cargar),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: controller.mensajes.length,
                  itemBuilder: (_, i) => BurbujaMensaje(mensaje: controller.mensajes[i]),
                ),
              ),
            ],
          ),
        },
      ),
    );
  }
}
