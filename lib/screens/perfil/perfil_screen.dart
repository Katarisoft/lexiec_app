import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/perfil_controller.dart';
import '../../controllers/tema_controller.dart';
import '../../data/models/perfil.dart';

/// "Mi cuenta": perfil, apariencia, seguridad, información y cierre de sesión.
class PerfilScreen extends GetView<PerfilController> {
  const PerfilScreen({super.key});

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

  void _avisoLegal(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: 'LexiEC',
    applicationLegalese: 'Consulta de la legislación ecuatoriana con inteligencia artificial.',
    children: const [
      SizedBox(height: AppSpacing.md),
      Text(
        'LexiEC ofrece orientación informativa basada en el texto de las normas cargadas y cita el artículo y la '
        'página de cada respuesta. No constituye asesoría legal: para un caso concreto consulta con un abogado.\n\n'
        'Tus consultas se guardan en tu cuenta y, cifradas, en este dispositivo. Puedes eliminarlas, o eliminar tu '
        'cuenta, en cualquier momento.',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    Widget seccion(String titulo) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, 0, AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(titulo, style: tema.textTheme.labelLarge?.copyWith(color: esquema.primary)),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Obx(() => _Cabecera(perfil: controller.perfil.value)),
          seccion('Apariencia'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema', style: tema.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Obx(() {
                    final temaCtrl = Get.find<TemaController>();
                    return SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.phone_android),
                            label: Text('Sistema'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Claro'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Oscuro'),
                          ),
                        ],
                        selected: {temaCtrl.modo.value},
                        showSelectedIcon: false,
                        onSelectionChanged: (seleccion) => temaCtrl.cambiar(seleccion.first),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          seccion('Seguridad'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset_outlined),
              title: const Text('Cambiar clave'),
              subtitle: const Text('Cierra tu sesión en los demás dispositivos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: controller.irACambiarClave,
            ),
          ),
          seccion('Información'),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Normas disponibles'),
                  subtitle: const Text('Sobre qué puedes preguntar'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.irANormas,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Aviso legal y privacidad'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _avisoLegal(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => _confirmarCierre(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: controller.irAEliminarCuenta,
            style: TextButton.styleFrom(foregroundColor: esquema.error),
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.perfil});

  final Perfil? perfil;

  String get _iniciales {
    final partes = (perfil?.nombreVisible ?? '?').split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final p = perfil;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: esquema.primary,
              foregroundColor: esquema.onPrimary,
              child: Text(_iniciales, style: tema.textTheme.titleLarge?.copyWith(color: esquema.onPrimary)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p?.nombreVisible ?? 'Tu cuenta', style: tema.textTheme.titleLarge),
                  if (p != null) ...[
                    Text('@${p.usuario}', style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
                    if (p.correo != null)
                      Text(p.correo!, style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Miembro desde ${DateFormat.yMMMMd('es').format(p.creadoEn.toLocal())}',
                      style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
