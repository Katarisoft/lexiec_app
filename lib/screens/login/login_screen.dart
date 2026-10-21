import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/login_controller.dart';
import '../../widgets/formulario.dart';
import '../../widgets/lexiec_marca.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: ContenidoFormulario(
        children: [
          const LexiecMarca(tamano: 64),
          const SizedBox(height: AppSpacing.xl),
          Text('Bienvenido de nuevo', style: tema.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Inicia sesión para continuar con tus consultas.',
            textAlign: TextAlign.center,
            style: tema.textTheme.bodyMedium?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => controller.errorGeneral.value == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AvisoError(mensaje: controller.errorGeneral.value!),
                  ),
          ),
          Obx(
            () => CampoTexto(
              controlador: controller.usuario,
              etiqueta: 'Usuario',
              icono: Icons.person_outline,
              error: controller.errores['usuario'],
              autocompletado: const [AutofillHints.username],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Obx(
            () => CampoTexto(
              controlador: controller.clave,
              etiqueta: 'Clave',
              icono: Icons.lock_outline,
              oculto: !controller.claveVisible.value,
              error: controller.errores['clave'],
              accion: TextInputAction.done,
              alEnviar: (_) => controller.iniciarSesion(),
              autocompletado: const [AutofillHints.password],
              sufijo: BotonVerClave(visible: controller.claveVisible.value, alPresionar: controller.alternarClave),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => BotonCarga(
              texto: 'Iniciar sesión',
              cargando: controller.cargando.value,
              alPresionar: controller.iniciarSesion,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('¿No tienes cuenta?', style: tema.textTheme.bodyMedium),
              TextButton(onPressed: controller.irARegistro, child: const Text('Crear cuenta')),
            ],
          ),
        ],
      ),
    );
  }
}
