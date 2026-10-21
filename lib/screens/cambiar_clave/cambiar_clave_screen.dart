import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/cambiar_clave_controller.dart';
import '../../widgets/formulario.dart';

class CambiarClaveScreen extends GetView<CambiarClaveController> {
  const CambiarClaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    const espacio = SizedBox(height: AppSpacing.md);
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar clave')),
      body: ContenidoFormulario(
        children: [
          Text(
            'Al cambiar tu clave se cerrará tu sesión en los demás dispositivos.',
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
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
              controlador: controller.actual,
              etiqueta: 'Clave actual',
              icono: Icons.lock_outline,
              oculto: !controller.visible.value,
              error: controller.errores['clave_actual'],
              autocompletado: const [AutofillHints.password],
              sufijo: BotonVerClave(visible: controller.visible.value, alPresionar: controller.alternarVisible),
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.nueva,
              etiqueta: 'Clave nueva',
              icono: Icons.lock_reset_outlined,
              oculto: !controller.visible.value,
              ayuda: 'Mínimo 12 caracteres y sin tu nombre de usuario.',
              error: controller.errores['clave_nueva'],
              autocompletado: const [AutofillHints.newPassword],
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.confirmacion,
              etiqueta: 'Repite la clave nueva',
              icono: Icons.lock_reset_outlined,
              oculto: !controller.visible.value,
              accion: TextInputAction.done,
              alEnviar: (_) => controller.guardar(),
              error: controller.errores['confirmacion'],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Obx(
            () => BotonCarga(
              texto: 'Guardar clave',
              cargando: controller.cargando.value,
              alPresionar: controller.guardar,
            ),
          ),
        ],
      ),
    );
  }
}
