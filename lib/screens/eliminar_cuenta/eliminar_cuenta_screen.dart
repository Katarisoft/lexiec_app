import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/eliminar_cuenta_controller.dart';
import '../../widgets/formulario.dart';

class EliminarCuentaScreen extends GetView<EliminarCuentaController> {
  const EliminarCuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar mi cuenta')),
      body: ContenidoFormulario(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: esquema.errorContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: esquema.onErrorContainer),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Esta acción no se puede deshacer',
                        style: tema.textTheme.titleMedium?.copyWith(color: esquema.onErrorContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Se eliminarán de forma permanente tu cuenta, todas tus consultas con sus respuestas y el '
                  'historial guardado en este dispositivo.',
                  style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onErrorContainer),
                ),
              ],
            ),
          ),
          Obx(
            () => controller.errorGeneral.value == null
                ? const SizedBox(height: AppSpacing.lg)
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: AvisoError(mensaje: controller.errorGeneral.value!),
                  ),
          ),
          Obx(
            () => CampoTexto(
              controlador: controller.clave,
              etiqueta: 'Tu clave',
              icono: Icons.lock_outline,
              oculto: !controller.visible.value,
              ayuda: 'Para confirmar que eres tú.',
              error: controller.errorClave.value,
              accion: TextInputAction.done,
              autocompletado: const [AutofillHints.password],
              sufijo: BotonVerClave(visible: controller.visible.value, alPresionar: controller.alternarVisible),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => CheckboxListTile(
              value: controller.entiendo.value,
              onChanged: controller.marcarEntiendo,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Entiendo que mi cuenta y mis consultas se borrarán para siempre.'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => FilledButton(
              style: FilledButton.styleFrom(backgroundColor: esquema.error, foregroundColor: esquema.onError),
              onPressed: controller.entiendo.value && !controller.cargando.value ? controller.eliminar : null,
              child: controller.cargando.value
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                  : const Text('Eliminar mi cuenta'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: () => Get.back<void>(), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
