import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/sesion_controller.dart';
import '../../widgets/estado_views.dart';

/// "Mis consultas" (ruta protegida). La lista, crear y eliminar llegan en la Fase 3.
class ConsultasScreen extends GetView<SesionController> {
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
    if (confirmar ?? false) await controller.cerrarSesion();
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
      body: Obx(
        () => EmptyView(
          icono: Icons.forum_outlined,
          titulo: 'Hola, ${controller.perfil.value?.nombreVisible ?? 'de nuevo'}',
          mensaje: 'Aquí verás tus consultas guardadas.',
        ),
      ),
    );
  }
}
