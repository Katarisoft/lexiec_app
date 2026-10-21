import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';

/// Respuesta en curso: "buscando…" y luego el texto provisional (se reemplaza por el verificado).
class BurbujaProvisional extends StatelessWidget {
  const BurbujaProvisional({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: texto.isEmpty ? 'El asistente está buscando en las normas' : null,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
          margin: const EdgeInsets.only(right: AppSpacing.lg, bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: esquema.surface,
            border: Border.all(color: esquema.outlineVariant.withValues(alpha: 0.7)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.sm),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (texto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(texto, style: tema.textTheme.bodyLarge?.copyWith(color: esquema.onSurfaceVariant)),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: esquema.secondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      texto.isEmpty ? 'Buscando en las normas…' : 'Verificando las fuentes…',
                      style: tema.textTheme.labelMedium?.copyWith(color: esquema.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inicio de una consulta vacía: preguntas sugeridas que se envían al tocarlas.
class SugerenciasConsulta extends StatelessWidget {
  const SugerenciasConsulta({super.key, required this.sugerencias, required this.alElegir, this.habilitado = true});

  final List<String> sugerencias;
  final ValueChanged<String> alElegir;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Icon(Icons.balance, size: 48, color: esquema.primary),
        const SizedBox(height: AppSpacing.md),
        Text('¿Qué quieres consultar?', textAlign: TextAlign.center, style: tema.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pregunta con tus palabras. Te responderé solo con lo que dicen las normas, citando el artículo.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final s in sugerencias)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              child: ListTile(
                enabled: habilitado,
                leading: Icon(Icons.lightbulb_outline, color: esquema.primary),
                title: Text(s),
                trailing: const Icon(Icons.north_east, size: 18),
                onTap: () => alElegir(s),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cuadro para escribir la pregunta, con aviso de error o de espera.
class CompositorPregunta extends StatelessWidget {
  const CompositorPregunta({
    super.key,
    required this.controlador,
    required this.habilitado,
    required this.enviando,
    required this.alEnviar,
    this.error,
    this.esperaSegundos = 0,
    this.maximo = 1000,
    this.saldo,
    this.alVerPlanes,
  });

  final TextEditingController controlador;
  final bool habilitado;
  final bool enviando;
  final VoidCallback alEnviar;
  final String? error;
  final int esperaSegundos;
  final int maximo;

  /// Consultas restantes ("Te quedan 3 consultas gratis este mes"), si aplica.
  final String? saldo;

  /// Con consultas agotadas: acción para abrir "Mi plan".
  final VoidCallback? alVerPlanes;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final aviso = esperaSegundos > 0 ? '${error ?? 'Espera un momento.'} ($esperaSegundos s)' : error;
    return Material(
      color: tema.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (aviso != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm, right: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: esquema.error),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(aviso, style: tema.textTheme.bodySmall?.copyWith(color: esquema.error)),
                        ),
                        if (alVerPlanes != null) TextButton(onPressed: alVerPlanes, child: const Text('Ver planes')),
                      ],
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controlador,
                      enabled: !enviando,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: maximo,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: enviando ? 'El asistente está respondiendo…' : 'Escribe tu pregunta',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controlador,
                    builder: (_, valor, _) => IconButton.filled(
                      tooltip: 'Enviar pregunta',
                      iconSize: 24,
                      constraints: const BoxConstraints.tightFor(width: 52, height: 52),
                      onPressed: habilitado && valor.text.trim().isNotEmpty ? alEnviar : null,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs, right: AppSpacing.sm),
                child: Text(
                  [?saldo, 'LexiEC orienta con base en las normas; revisa siempre las fuentes citadas.'].join(' · '),
                  style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
