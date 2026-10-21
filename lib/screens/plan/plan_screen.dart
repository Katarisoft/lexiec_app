import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../controllers/plan_controller.dart';
import '../../controllers/sesion_controller.dart';
import '../../controllers/view_status.dart';
import '../../core/config/app_config.dart';
import '../../data/models/plan.dart';
import '../../widgets/avisos.dart';
import '../../widgets/estado_views.dart';

/// "Mi plan": saldo de consultas, paquetes vigentes, planes a la venta y cómo comprarlos.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  final PlanController controller = Get.find<PlanController>();

  @override
  void initState() {
    super.initState();
    controller.cargar(); // el controlador es global: se recarga cada vez que se abre la pantalla
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi plan')),
      body: Obx(
        () => switch (controller.estado.value) {
          ViewStatus.loading => const EsqueletoLista(elementos: 3),
          ViewStatus.error => ErrorView(mensaje: controller.mensajeError.value, onReintentar: controller.cargar),
          ViewStatus.empty || ViewStatus.success => RefreshIndicator(
            onRefresh: controller.cargar,
            child: _Contenido(controller: controller),
          ),
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.controller});

  final PlanController controller;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final plan = controller.plan.value!;
    Widget seccion(String titulo) => Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, 0, AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(titulo, style: tema.textTheme.labelLarge?.copyWith(color: esquema.primary)),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _TarjetaSaldo(plan: plan, fecha: controller.fechaCorta),
        if (plan.lotes.isNotEmpty) ...[
          seccion('Tus paquetes'),
          for (final lote in plan.lotes) _TarjetaLote(lote: lote, vence: controller.fechaCorta(lote.venceEn)),
        ],
        if (controller.catalogo.isNotEmpty) ...[
          seccion('Planes con IA rápida'),
          for (final p in controller.catalogo) _TarjetaPlan(plan: p),
        ],
        seccion('Cómo comprar'),
        _ComoComprar(controller: controller),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Solo se descuentan las respuestas con fuentes verificadas. Si el asistente no encuentra '
          'información en las normas, esa consulta no se cobra.',
          style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  const _TarjetaSaldo({required this.plan, required this.fecha});

  final EstadoPlan plan;
  final String Function(DateTime) fecha;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final marca = ColoresMarca.de(context);
    final (etiqueta, cifra, detalle) = switch (plan.modo) {
      ModoPlan.cortesia => ('Cuenta de cortesía', '∞', 'Consultas sin límite con IA rápida.'),
      ModoPlan.pagado => (
        'Plan pagado',
        '${plan.consultasPagadas}',
        plan.consultasPagadas == 1 ? 'consulta disponible con IA rápida' : 'consultas disponibles con IA rápida',
      ),
      ModoPlan.gratis => (
        'Plan gratis',
        '${plan.gratisRestantes}',
        'de ${plan.gratisLimite} consultas gratis este mes · se renuevan el ${fecha(plan.gratisRenuevaEn)}',
      ),
      ModoPlan.sinSaldo => (
        'Sin consultas',
        '0',
        'Usaste tus consultas gratis del mes. Se renuevan el ${fecha(plan.gratisRenuevaEn)} o puedes comprar un paquete.',
      ),
      ModoPlan.desconocido => ('Tu plan', '—', 'Actualiza la app para ver el detalle de tu plan.'),
    };
    return Semantics(
      container: true,
      label: '$etiqueta. $cifra $detalle',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: marca.degradado, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(plan.iaRapida ? Icons.bolt : Icons.workspace_premium_outlined, color: marca.textoSobreMarca),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(etiqueta, style: tema.textTheme.titleMedium?.copyWith(color: marca.textoSobreMarca)),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(cifra, style: tema.textTheme.displayMedium?.copyWith(color: marca.textoSobreMarca)),
              Text(detalle, style: tema.textTheme.bodyMedium?.copyWith(color: marca.textoSobreMarcaSuave)),
              if (!plan.iaRapida && plan.modo != ModoPlan.desconocido) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Las consultas gratis usan el modelo estándar, que puede tardar más.',
                  style: tema.textTheme.bodySmall?.copyWith(color: marca.textoSobreMarcaSuave),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaLote extends StatelessWidget {
  const _TarjetaLote({required this.lote, required this.vence});

  final LoteVigente lote;
  final String vence;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(lote.nombre, style: tema.textTheme.titleMedium)),
                Text('${lote.restantes} de ${lote.total}', style: tema.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: lote.total == 0 ? 0 : lote.restantes / lote.total,
              semanticsLabel: 'Consultas restantes del ${lote.nombre}',
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Vence el $vence', style: tema.textTheme.bodySmall?.copyWith(color: esquema.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({required this.plan});

  final PlanCatalogo plan;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final marca = ColoresMarca.de(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(plan.nombre, style: tema.textTheme.titleMedium)),
                Text(
                  '\$${plan.precioUsd}',
                  style: tema.textTheme.titleLarge?.copyWith(color: marca.acentoTexto, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${plan.consultas} consultas · válidas ${plan.vigencia}',
              style: tema.textTheme.labelLarge?.copyWith(color: esquema.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(plan.descripcion, style: tema.textTheme.bodyMedium?.copyWith(color: esquema.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ComoComprar extends StatelessWidget {
  const _ComoComprar({required this.controller});

  final PlanController controller;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final usuario = Get.find<SesionController>().perfil.value?.usuario;
    Widget paso(int n, String texto) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text('$n', style: tema.textTheme.labelMedium)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(texto, style: tema.textTheme.bodyMedium)),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            paso(1, 'Elige un plan en consultaslegales.app.'),
            paso(
              2,
              usuario == null
                  ? 'Paga y envía el comprobante indicando tu usuario.'
                  : 'Paga y envía el comprobante indicando tu usuario: @$usuario',
            ),
            paso(3, 'Acreditamos tus consultas y aparecerán aquí.'),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(AppConfig.urlPlanes, style: tema.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await controller.copiarEnlaceCompra();
                  mostrarAviso('Enlace copiado. Ábrelo en tu navegador.');
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar enlace de compra'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
