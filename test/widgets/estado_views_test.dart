import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lexiec/app/theme/app_theme.dart';
import 'package:lexiec/widgets/estado_views.dart';

Widget _envolver(Widget hijo) => MaterialApp(
  theme: AppTheme.claro(),
  home: Scaffold(body: hijo),
);

void main() {
  testWidgets('LoadingView muestra indicador y mensaje', (tester) async {
    await tester.pumpWidget(_envolver(const LoadingView(mensaje: 'Cargando consultas')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Cargando consultas'), findsOneWidget);
  });

  testWidgets('EmptyView muestra la acción sugerida y la ejecuta', (tester) async {
    var pulsado = false;
    await tester.pumpWidget(
      _envolver(
        EmptyView(
          titulo: 'Aún no tienes consultas',
          mensaje: 'Haz tu primera pregunta',
          textoAccion: 'Nueva consulta',
          onAccion: () => pulsado = true,
        ),
      ),
    );
    expect(find.text('Aún no tienes consultas'), findsOneWidget);
    await tester.tap(find.text('Nueva consulta'));
    expect(pulsado, isTrue);
  });

  testWidgets('EmptyView sin acción no muestra botón', (tester) async {
    await tester.pumpWidget(_envolver(const EmptyView(titulo: 'Vacío', mensaje: 'Nada por aquí')));
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('ErrorView muestra el mensaje y el botón Reintentar funciona', (tester) async {
    var reintentos = 0;
    await tester.pumpWidget(_envolver(ErrorView(mensaje: 'Revisa tu conexión', onReintentar: () => reintentos++)));
    expect(find.text('Revisa tu conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(reintentos, 1);
  });
}
