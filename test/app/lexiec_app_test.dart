import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/lexiec_app.dart';
import 'package:lexiec/core/errors/reporte_errores.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/widgets/lexiec_marca.dart';

import '../helpers/app_prueba.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('la app arranca mostrando la marca mientras decide el destino', (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(LexiecApp(bindingInicial: BindingPrueba(repositorioBase(), EventosSesion())));
    expect(find.byType(LexiecMarca), findsOneWidget);
    expect(find.text('La ley ecuatoriana, explicada con sus fuentes'), findsOneWidget);
    expect(find.bySemanticsLabel('LexiEC'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });

  testWidgets('ErrorDeSeccion reemplaza la pantalla roja con un mensaje amable', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorDeSeccion()));
    expect(find.text('Esta sección no se pudo mostrar.'), findsOneWidget);
  });
}
