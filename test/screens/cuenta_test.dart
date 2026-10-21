import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/models/documento.dart';
import 'package:lexiec/screens/cambiar_clave/cambiar_clave_screen.dart';
import 'package:lexiec/screens/consultas/consultas_screen.dart';
import 'package:lexiec/screens/eliminar_cuenta/eliminar_cuenta_screen.dart';
import 'package:lexiec/screens/login/login_screen.dart';
import 'package:lexiec/screens/perfil/perfil_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

Finder _campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

Future<AuthRepositoryMock> _enMiCuenta(WidgetTester tester, {PreferenciasRepositoryMock? preferencias}) async {
  final repo = repositorioBase(sesionGuardada: true);
  await montarApp(tester, repo, preferencias: preferencias);
  await abrirMiCuenta(tester);
  expect(find.byType(PerfilScreen), findsOneWidget);
  return repo;
}

Future<void> _irA(WidgetTester tester, String texto) async {
  await tester.scrollUntilVisible(find.text(texto), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  group('Mi cuenta', () {
    testWidgets('muestra el perfil con iniciales, usuario y fecha de alta', (tester) async {
      await _enMiCuenta(tester);
      expect(find.text('María Pérez'), findsOneWidget);
      expect(find.text('@maria.perez'), findsOneWidget);
      expect(find.text('MP'), findsOneWidget);
      expect(find.textContaining('Miembro desde'), findsOneWidget);
    });

    testWidgets('el tema elegido se aplica al instante y se guarda', (tester) async {
      final preferencias = preferenciasBase();
      await _enMiCuenta(tester, preferencias: preferencias);
      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();
      verify(() => preferencias.guardarTema(ThemeMode.dark)).called(1);
      expect(Theme.of(tester.element(find.byType(PerfilScreen))).brightness, Brightness.dark);
    });

    testWidgets('el tema guardado se aplica al abrir la app', (tester) async {
      final preferencias = preferenciasBase();
      when(preferencias.tema).thenAnswer((_) async => ThemeMode.dark);
      await montarApp(tester, repositorioBase(sesionGuardada: true), preferencias: preferencias);
      expect(Theme.of(tester.element(find.byType(ConsultasScreen))).brightness, Brightness.dark);
    });
  });

  group('Cambiar clave', () {
    testWidgets('valida localmente: nueva igual a la actual', (tester) async {
      final repo = await _enMiCuenta(tester);
      await _irA(tester, 'Cambiar clave');
      await tester.enterText(_campo('Clave actual'), 'una clave larga actual');
      await tester.enterText(_campo('Clave nueva'), 'una clave larga actual');
      await tester.enterText(_campo('Repite la clave nueva'), 'una clave larga actual');
      await tester.tap(find.text('Guardar clave'));
      await tester.pump();
      expect(find.text('La clave nueva debe ser distinta de la actual.'), findsOneWidget);
      verifyNever(() => repo.cambiarClave(any(), any()));
    });

    testWidgets('clave actual incorrecta (400) se muestra en su campo', (tester) async {
      final repo = await _enMiCuenta(tester);
      when(
        () => repo.cambiarClave(any(), any()),
      ).thenThrow(const BadRequestException(detalle: 'La clave actual es incorrecta.'));
      await _irA(tester, 'Cambiar clave');
      await tester.enterText(_campo('Clave actual'), 'equivocada');
      await tester.enterText(_campo('Clave nueva'), 'una frase nueva y segura');
      await tester.enterText(_campo('Repite la clave nueva'), 'una frase nueva y segura');
      await tester.tap(find.text('Guardar clave'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(_campo('Clave actual')).decoration?.errorText, 'La clave actual es incorrecta.');
    });

    testWidgets('cambio correcto vuelve a Mi cuenta y lo confirma', (tester) async {
      final repo = await _enMiCuenta(tester);
      when(() => repo.cambiarClave(any(), any())).thenAnswer((_) async {});
      await _irA(tester, 'Cambiar clave');
      expect(find.byType(CambiarClaveScreen), findsOneWidget);
      await tester.enterText(_campo('Clave actual'), 'la clave de antes');
      await tester.enterText(_campo('Clave nueva'), 'una frase nueva y segura');
      await tester.enterText(_campo('Repite la clave nueva'), 'una frase nueva y segura');
      await tester.tap(find.text('Guardar clave'));
      await tester.pumpAndSettle();
      verify(() => repo.cambiarClave('la clave de antes', 'una frase nueva y segura')).called(1);
      expect(find.byType(PerfilScreen), findsOneWidget);
      expect(find.textContaining('Clave actualizada'), findsOneWidget);
    });
  });

  group('Eliminar cuenta', () {
    testWidgets('el botón requiere confirmar que se entiende', (tester) async {
      await _enMiCuenta(tester);
      await _irA(tester, 'Eliminar mi cuenta');
      expect(find.byType(EliminarCuentaScreen), findsOneWidget);
      final boton = find.widgetWithText(FilledButton, 'Eliminar mi cuenta');
      expect(tester.widget<FilledButton>(boton).onPressed, isNull);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(tester.widget<FilledButton>(boton).onPressed, isNotNull);
    });

    testWidgets('clave incorrecta (400) no elimina nada', (tester) async {
      final repo = await _enMiCuenta(tester);
      when(() => repo.eliminarCuenta(any())).thenThrow(const BadRequestException(detalle: 'La clave es incorrecta.'));
      await _irA(tester, 'Eliminar mi cuenta');
      await tester.enterText(_campo('Tu clave'), 'equivocada');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('La clave es incorrecta.'), findsOneWidget);
      expect(find.byType(EliminarCuentaScreen), findsOneWidget);
    });

    testWidgets('eliminación correcta: vuelve al login, avisa y borra el historial local', (tester) async {
      final repo = repositorioBase(sesionGuardada: true);
      final conversaciones = conversacionesVacias();
      when(() => repo.eliminarCuenta(any())).thenAnswer((_) async {});
      await montarApp(tester, repo, conversaciones: conversaciones);
      await abrirMiCuenta(tester);
      await _irA(tester, 'Eliminar mi cuenta');
      await tester.enterText(_campo('Tu clave'), 'mi clave correcta');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Eliminar mi cuenta'));
      await tester.pumpAndSettle();
      verify(() => repo.eliminarCuenta('mi clave correcta')).called(1);
      verify(conversaciones.limpiarHistorialLocal).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Tu cuenta y tus consultas fueron eliminadas.'), findsOneWidget);
    });
  });

  group('Normas disponibles', () {
    testWidgets('lista las normas con sus páginas desde "Mis consultas"', (tester) async {
      final documentos = DocumentosRepositoryMock();
      when(documentos.listar).thenAnswer(
        (_) async => [
          Documento(
            archivo: 'Codigo-Organico-Integral-Penal2025.pdf',
            paginas: 387,
            fragmentos: 1664,
            indexadoEn: DateTime.utc(2026, 10, 20),
          ),
          Documento(
            archivo: 'mesicic4_ecu_const.pdf',
            paginas: 136,
            fragmentos: 617,
            indexadoEn: DateTime.utc(2026, 10, 20),
          ),
        ],
      );
      await montarApp(tester, repositorioBase(sesionGuardada: true), documentos: documentos);
      await tester.tap(find.byTooltip('Normas disponibles'));
      await tester.pumpAndSettle();
      expect(find.textContaining('estas 2 normas'), findsOneWidget);
      expect(find.text('Codigo Organico Integral Penal2025'), findsOneWidget);
      expect(find.textContaining('387 páginas'), findsOneWidget);
    });

    testWidgets('error al cargar: mensaje y Reintentar', (tester) async {
      final documentos = DocumentosRepositoryMock();
      var llamadas = 0;
      when(documentos.listar).thenAnswer((_) async {
        if (llamadas++ == 0) throw const NetworkException();
        return const [];
      });
      await montarApp(tester, repositorioBase(sesionGuardada: true), documentos: documentos);
      await tester.tap(find.byTooltip('Normas disponibles'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay normas cargadas'), findsOneWidget);
    });
  });
}
