import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/consulta_controller.dart';
import '../../controllers/view_status.dart';
import '../../widgets/burbuja_mensaje.dart';
import '../../widgets/chat_widgets.dart';
import '../../widgets/estado_views.dart';

/// Chat de una consulta: historial con fuentes y nueva pregunta con respuesta en streaming.
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
          ViewStatus.empty || ViewStatus.success => Column(
            children: [
              if (controller.sinConexion.value) AvisoSinConexion(alReintentar: controller.cargar),
              Expanded(
                child: controller.estado.value == ViewStatus.empty
                    ? SugerenciasConsulta(
                        sugerencias: ConsultaController.sugerencias,
                        habilitado: controller.puedeEnviar,
                        alElegir: controller.enviar,
                      )
                    : const _Conversacion(),
              ),
              CompositorPregunta(
                controlador: controller.pregunta,
                habilitado: controller.puedeEnviar,
                enviando: controller.enviando.value,
                error: controller.errorEnvio.value,
                esperaSegundos: controller.esperaSegundos.value,
                maximo: ConsultaController.maximoCaracteres,
                alEnviar: controller.enviar,
                saldo: controller.plan.resumenSaldo,
                alVerPlanes: controller.sinConsultas.value ? controller.plan.irAPlan : null,
              ),
            ],
          ),
        },
      ),
    );
  }
}

/// Mensajes del más reciente (abajo) al más antiguo: la lista invertida mantiene
/// siempre visible lo último sin desplazar a mano.
class _Conversacion extends GetView<ConsultaController> {
  const _Conversacion();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Se leen aquí (no dentro de itemBuilder) para que Obx se suscriba y repinte con cada fragmento.
      final mensajes = controller.mensajes.toList();
      final escribiendo = controller.enviando.value;
      final textoProvisional = controller.provisional.value;
      return ListView.builder(
        reverse: true,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: mensajes.length + (escribiendo ? 1 : 0),
        itemBuilder: (_, i) {
          if (escribiendo && i == 0) return BurbujaProvisional(texto: textoProvisional);
          final indice = mensajes.length - 1 - (escribiendo ? i - 1 : i);
          return BurbujaMensaje(key: ValueKey(mensajes[indice].id), mensaje: mensajes[indice]);
        },
      );
    });
  }
}
