import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/registro_controller.dart';
import '../../widgets/formulario.dart';

class RegistroScreen extends GetView<RegistroController> {
  const RegistroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    Widget seccion(String titulo) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(titulo, style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.primary)),
    );
    const espacio = SizedBox(height: AppSpacing.md);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: ContenidoFormulario(
        children: [
          Text(
            'Con tu cuenta, tus consultas quedan guardadas y puedes retomarlas desde cualquier dispositivo.',
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          Obx(
            () => controller.errorGeneral.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: AvisoError(mensaje: controller.errorGeneral.value!),
                  ),
          ),
          seccion('Acceso'),
          Obx(
            () => CampoTexto(
              controlador: controller.usuario,
              etiqueta: 'Usuario',
              icono: Icons.person_outline,
              ayuda: 'De 3 a 50 caracteres: letras, números, punto, guion o guion bajo.',
              error: controller.errores['usuario'],
              autocompletado: const [AutofillHints.newUsername],
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.clave,
              etiqueta: 'Clave',
              icono: Icons.lock_outline,
              oculto: !controller.claveVisible.value,
              ayuda: 'Mínimo 12 caracteres. Una frase corta es fácil de recordar y segura.',
              error: controller.errores['clave'],
              autocompletado: const [AutofillHints.newPassword],
              sufijo: BotonVerClave(visible: controller.claveVisible.value, alPresionar: controller.alternarClave),
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.confirmacion,
              etiqueta: 'Repite la clave',
              icono: Icons.lock_reset_outlined,
              oculto: !controller.claveVisible.value,
              error: controller.errores['confirmacion'],
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.codigo,
              etiqueta: 'Código de invitación',
              icono: Icons.vpn_key_outlined,
              ayuda: 'Te lo entrega la administración de LexiEC.',
              error: controller.errores['codigo_invitacion'],
            ),
          ),
          seccion('Datos opcionales'),
          Obx(
            () => CampoTexto(
              controlador: controller.nombre,
              etiqueta: 'Nombre (opcional)',
              icono: Icons.badge_outlined,
              mayusculas: TextCapitalization.words,
              error: controller.errores['nombre'],
              autocompletado: const [AutofillHints.name],
            ),
          ),
          espacio,
          Obx(
            () => CampoTexto(
              controlador: controller.correo,
              etiqueta: 'Correo (opcional)',
              icono: Icons.alternate_email,
              teclado: TextInputType.emailAddress,
              accion: TextInputAction.done,
              alEnviar: (_) => controller.registrar(),
              error: controller.errores['correo'],
              autocompletado: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Obx(
            () => BotonCarga(
              texto: 'Crear cuenta',
              cargando: controller.cargando.value,
              alPresionar: controller.registrar,
            ),
          ),
        ],
      ),
    );
  }
}
