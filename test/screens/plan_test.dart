import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/core/config/app_config.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/models/plan.dart';
import 'package:lexiec/screens/plan/plan_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

Future<void> _abrirMiPlan(WidgetTester tester, PlanesRepositoryMock planes) async {
  await montarApp(tester, repositorioBase(sesionGuardada: true), planes: planes);
  await abrirMiCuenta(tester);
  await tester.tap(find.text('Mi plan'));
  await tester.pumpAndSettle();
  expect(find.byType(PlanScreen), findsOneWidget);
}

void main() {
  tearDown(Get.reset);

  testWidgets('plan gratis: saldo del mes, planes a la venta y cómo comprar', (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
      if (llamada.method == 'Clipboard.setData') copiado = (llamada.arguments as Map)['text'] as String;
      return null;
    });
    await _abrirMiPlan(tester, planesBase());

    expect(find.text('Plan gratis'), findsOneWidget);
    expect(find.textContaining('de 5 consultas gratis este mes'), findsOneWidget);
    expect(find.text('Paquete 20'), findsOneWidget);
    expect(find.text(r'$4.99'), findsOneWidget);
    expect(find.textContaining('@maria.perez'), findsOneWidget); // usuario para el comprobante

    await tester.scrollUntilVisible(
      find.text('Copiar enlace de compra'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -300)); // el botón, lejos del borde
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar enlace de compra'));
    await tester.pumpAndSettle();
    expect(copiado, AppConfig.urlPlanes);
    expect(find.textContaining('Enlace copiado'), findsOneWidget);
  });

  testWidgets('plan pagado: consultas disponibles y avance de cada paquete', (tester) async {
    final saldo = EstadoPlan(
      modo: ModoPlan.pagado,
      iaRapida: true,
      consultasPagadas: 18,
      gratisLimite: 5,
      gratisRestantes: 5,
      gratisRenuevaEn: DateTime.utc(2026, 11, 1, 5),
      lotes: [
        LoteVigente(
          plan: 'paquete_20',
          nombre: 'Paquete 20',
          restantes: 18,
          total: 20,
          venceEn: DateTime.utc(2027, 4, 19),
        ),
      ],
    );
    await _abrirMiPlan(tester, planesBase(saldo: saldo));

    expect(find.text('Plan pagado'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('18 de 20'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('error al cargar: mensaje y Reintentar', (tester) async {
    final planes = planesBase();
    when(planes.estado).thenAnswer((_) async => throw const NetworkException());
    await _abrirMiPlan(tester, planes);

    expect(find.textContaining('Sin conexión'), findsOneWidget);
    when(planes.estado).thenAnswer((_) async => saldoGratis);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Plan gratis'), findsOneWidget);
  });
}
