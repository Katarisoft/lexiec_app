import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_spacing.dart';
import '../../controllers/bienvenida_controller.dart';

class _Lamina {
  const _Lamina(this.icono, this.titulo, this.texto);

  final IconData icono;
  final String titulo;
  final String texto;
}

const _laminas = [
  _Lamina(
    Icons.forum_outlined,
    'Pregunta como hablas',
    'Escribe tu duda sobre la ley ecuatoriana con tus propias palabras y continúa la conversación con preguntas de seguimiento.',
  ),
  _Lamina(
    Icons.menu_book_outlined,
    'Respuestas con su fuente',
    'Cada respuesta indica el artículo y la página de la norma, con el texto literal para que lo compruebes.',
  ),
  _Lamina(
    Icons.gavel_outlined,
    'Orientación, no asesoría',
    'LexiEC te ayuda a entender la normativa. Para un caso concreto, consulta con un abogado.',
  ),
];

class BienvenidaScreen extends GetView<BienvenidaController> {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Obx(
                () => AnimatedOpacity(
                  opacity: controller.esUltima ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: controller.esUltima ? null : controller.terminar,
                    child: const Text('Saltar'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller.paginas,
                itemCount: _laminas.length,
                onPageChanged: controller.alCambiarPagina,
                itemBuilder: (_, i) => _VistaLamina(lamina: _laminas[i]),
              ),
            ),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _laminas.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      width: controller.pagina.value == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.pagina.value == i
                            ? tema.colorScheme.primary
                            : tema.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Obx(
                () => FilledButton(
                  onPressed: controller.siguiente,
                  child: Text(controller.esUltima ? 'Comenzar' : 'Siguiente'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VistaLamina extends StatelessWidget {
  const _VistaLamina({required this.lamina});

  final _Lamina lamina;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    // Desplazable para letra grande o pantallas bajas; centrada cuando cabe.
    return LayoutBuilder(
      builder: (_, limites) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: limites.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(color: tema.colorScheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(lamina.icono, size: 64, color: tema.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(lamina.titulo, textAlign: TextAlign.center, style: tema.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              Text(
                lamina.texto,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyLarge?.copyWith(color: tema.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
