import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/conversaciones_controller.dart';
import '../../controllers/sesion_controller.dart';
import '../../controllers/view_status.dart';
import '../../data/models/conversacion.dart';
import '../../widgets/estado_views.dart';
import '../../widgets/formato_fecha.dart';
import '../../widgets/tarjeta_consulta.dart';

/// "Mis consultas": lista principal (datos reales de la API, con historial local cifrado).
class ConsultasScreen extends GetView<ConversacionesController> {
  const ConsultasScreen({super.key});

  Future<void> _confirmarCierre(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tendrás que ingresar tu usuario y clave para volver.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexto, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(contexto, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmar ?? false) await Get.find<SesionController>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis consultas'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmarCierre(context),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => controller.estado.value == ViewStatus.success
            ? FloatingActionButton.extended(
                onPressed: controller.creando.value ? null : controller.nuevaConsulta,
                icon: controller.creando.value
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
                    : const Icon(Icons.add_comment_outlined),
                label: const Text('Nueva consulta'),
              )
            : const SizedBox.shrink(),
      ),
      body: Obx(
        () => switch (controller.estado.value) {
          ViewStatus.loading => const EsqueletoLista(),
          ViewStatus.error => ErrorView(mensaje: controller.mensajeError.value, onReintentar: controller.cargar),
          ViewStatus.empty => EmptyView(
            icono: Icons.forum_outlined,
            titulo: 'Aún no tienes consultas',
            mensaje:
                'Pregunta sobre la Constitución, el COIP o la Ley de Tránsito y recibe la respuesta con el artículo exacto.',
            textoAccion: 'Nueva consulta',
            onAccion: controller.nuevaConsulta,
          ),
          ViewStatus.success => const _Lista(),
        },
      ),
    );
  }
}

class _Lista extends GetView<ConversacionesController> {
  const _Lista();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        Obx(
          () => controller.sinConexion.value
              ? AvisoSinConexion(alReintentar: controller.refrescar)
              : const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: TextField(
            onChanged: (texto) => controller.filtro.value = texto,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Buscar en mis consultas',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final items = controller.visibles;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Ninguna consulta coincide con «${controller.filtro.value}».',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                  ),
                ),
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 400) controller.cargarMas();
                return false;
              },
              child: RefreshIndicator(
                onRefresh: controller.refrescar,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // espacio inferior para que el botón flotante no tape la última tarjeta
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
                  itemCount: items.length + 1,
                  itemBuilder: (_, i) {
                    if (i == items.length) {
                      return controller.cargandoMas.value
                          ? const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LoadingView())
                          : const SizedBox.shrink();
                    }
                    return _ElementoConGrupo(conversacion: items[i], anterior: i == 0 ? null : items[i - 1]);
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ElementoConGrupo extends GetView<ConversacionesController> {
  const _ElementoConGrupo({required this.conversacion, this.anterior});

  final Conversacion conversacion;
  final Conversacion? anterior;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final grupo = FormatoFecha.grupo(conversacion.actualizadaEn);
    final nuevoGrupo = anterior == null || FormatoFecha.grupo(anterior!.actualizadaEn) != grupo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nuevoGrupo)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.md, 0, AppSpacing.sm),
            child: Semantics(
              header: true,
              child: Text(grupo, style: tema.textTheme.labelLarge?.copyWith(color: tema.colorScheme.primary)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TarjetaConsulta(
            conversacion: conversacion,
            alAbrir: () => controller.abrir(conversacion),
            alEliminar: () => controller.eliminarConDeshacer(conversacion),
          ),
        ),
      ],
    );
  }
}
