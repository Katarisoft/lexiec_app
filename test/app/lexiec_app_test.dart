import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/app/lexiec_app.dart';
import 'package:lexiec/core/errors/reporte_errores.dart';
import 'package:lexiec/widgets/lexiec_marca.dart';

void main() {
  testWidgets('la app arranca en la pantalla de inicio con la marca', (tester) async {
    await tester.pumpWidget(const LexiecApp());
    expect(find.byType(LexiecMarca), findsOneWidget);
    expect(find.text('La ley ecuatoriana, explicada con sus fuentes'), findsOneWidget);
    expect(find.bySemanticsLabel('LexiEC'), findsOneWidget);
  });

  testWidgets('ErrorDeSeccion reemplaza la pantalla roja con un mensaje amable', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorDeSeccion()));
    expect(find.text('Esta sección no se pudo mostrar.'), findsOneWidget);
  });
}
