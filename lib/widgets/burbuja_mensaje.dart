import 'package:flutter/material.dart';

import '../app/theme/app_spacing.dart';
import '../data/models/cita.dart';
import '../data/models/mensaje.dart';
import '../data/models/respuesta_chat.dart';

/// Burbuja de una pregunta (derecha) o respuesta (izquierda, con sus citas).
class BurbujaMensaje extends StatelessWidget {
  const BurbujaMensaje({super.key, required this.mensaje});

  final Mensaje mensaje;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final ancho = MediaQuery.sizeOf(context).width * 0.86;

    if (mensaje.esDelUsuario) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: ancho),
          margin: const EdgeInsets.only(left: AppSpacing.xl, bottom: AppSpacing.md),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: esquema.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(AppRadius.sm),
            ),
          ),
          child: SelectableText(mensaje.contenido, style: tema.textTheme.bodyLarge?.copyWith(color: esquema.onPrimary)),
        ),
      );
    }

    final sinInformacion = mensaje.citas.isEmpty && mensaje.contenido == RespuestaChat.textoSinInformacion;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: ancho),
        margin: const EdgeInsets.only(right: AppSpacing.lg, bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: sinInformacion ? esquema.surfaceContainerHighest : esquema.surface,
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
          children: [
            if (sinInformacion)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(Icons.search_off, size: 18, color: esquema.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Sin respuesta en las normas', style: tema.textTheme.labelLarge),
                  ],
                ),
              ),
            SelectableText(mensaje.contenido, style: tema.textTheme.bodyLarge),
            if (sinInformacion)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Prueba a reformular la pregunta o a mencionar la norma (Constitución, COIP, Ley de Tránsito).',
                  style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                ),
              ),
            if (mensaje.citas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Fuentes', style: tema.textTheme.labelMedium?.copyWith(color: esquema.onSurfaceVariant)),
              // Agrupadas por documento: el mismo artículo puede existir en varias normas o versiones.
              for (final MapEntry(key: documento, value: citas) in _porDocumento(mensaje.citas).entries) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.description_outlined, size: 16, color: esquema.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        documento,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [for (final cita in citas) ChipCita(cita: cita)],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Citas agrupadas por documento, con una sola ficha por artículo y página
  /// (la API puede citar varias frases del mismo artículo).
  static Map<String, List<Cita>> _porDocumento(List<Cita> citas) {
    final grupos = <String, List<Cita>>{};
    final vistas = <String>{};
    for (final c in citas) {
      if (vistas.add('${c.archivo}|${c.referencia}')) (grupos[c.documento] ??= []).add(c);
    }
    return grupos;
  }
}

/// Ficha "Art. 36 · pág. 18" que abre el texto literal de la norma.
class ChipCita extends StatelessWidget {
  const ChipCita({super.key, required this.cita});

  final Cita cita;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.menu_book_outlined, size: 18),
      label: Text(cita.referencia),
      tooltip: 'Ver el texto de ${cita.referencia}',
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => HojaCita(cita: cita),
      ),
    );
  }
}

/// Texto literal de la cita, con el documento de origen.
class HojaCita extends StatelessWidget {
  const HojaCita({super.key, required this.cita});

  final Cita cita;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cita.referencia, style: tema.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(cita.documento, style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: esquema.surfaceContainerHighest.withValues(alpha: 0.6),
                border: Border(left: BorderSide(color: esquema.secondary, width: 4)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SelectableText(
                '«${cita.texto}»',
                style: tema.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Texto literal de la norma. LexiEC orienta; no reemplaza la asesoría de un abogado.',
              style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
