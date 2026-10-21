import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/routes/app_routes.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/screens/bienvenida/bienvenida_screen.dart';
import 'package:lexiec/screens/consultas/consultas_screen.dart';
import 'package:lexiec/screens/login/login_screen.dart';
import 'package:lexiec/screens/registro/registro_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

Finder _campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

void main() {
  tearDown(Get.reset);

  group('Inicio', () {
    testWidgets('primera vez: muestra la bienvenida y "Saltar" lleva al login', (tester) async {
      final repo = repositorioBase(bienvenidaVista: false);
      await montarApp(tester, repo);
      expect(find.byType(BienvenidaScreen), findsOneWidget);
      expect(find.text('Pregunta como hablas'), findsOneWidget);

      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();
      verify(repo.marcarBienvenidaVista).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('con sesión guardada válida entra directo a "Mis consultas"', (tester) async {
      await montarApp(tester, repositorioBase(sesionGuardada: true));
      expect(find.byType(ConsultasScreen), findsOneWidget);
      expect(find.text('Hola, María Pérez'), findsOneWidget);
    });

    testWidgets('sesión guardada pero rechazada (401) va al login', (tester) async {
      final repo = repositorioBase(sesionGuardada: true);
      when(repo.perfil).thenThrow(const UnauthorizedException());
      await montarApp(tester, repo);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('sin conexión con sesión guardada entra igual (datos locales)', (tester) async {
      final repo = repositorioBase(sesionGuardada: true);
      when(repo.perfil).thenThrow(const NetworkException());
      await montarApp(tester, repo);
      expect(find.byType(ConsultasScreen), findsOneWidget);
    });
  });

  group('Rutas protegidas', () {
    testWidgets('sin sesión, ir a "Mis consultas" redirige al login', (tester) async {
      await montarApp(tester, repositorioBase());
      unawaited(Get.toNamed<void>(AppRoutes.consultas));
      await tester.pumpAndSettle();
      expect(find.byType(ConsultasScreen), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Login', () {
    testWidgets('campos vacíos: errores en cada campo y no llama a la API', (tester) async {
      final repo = repositorioBase();
      await montarApp(tester, repo);
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump();
      expect(find.text('Ingresa tu usuario.'), findsOneWidget);
      expect(find.text('Ingresa tu clave.'), findsOneWidget);
      verifyNever(() => repo.iniciarSesion(any(), any()));
    });

    testWidgets('credenciales incorrectas muestran el mensaje del servidor', (tester) async {
      final repo = repositorioBase();
      when(
        () => repo.iniciarSesion(any(), any()),
      ).thenThrow(const UnauthorizedException(detalle: 'Usuario o clave incorrectos.'));
      await montarApp(tester, repo);
      await tester.enterText(_campo('Usuario'), 'maria.perez');
      await tester.enterText(_campo('Clave'), 'mala');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Usuario o clave incorrectos.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('sin conexión muestra un mensaje distinto', (tester) async {
      final repo = repositorioBase();
      when(() => repo.iniciarSesion(any(), any())).thenThrow(const NetworkException());
      await montarApp(tester, repo);
      await tester.enterText(_campo('Usuario'), 'maria.perez');
      await tester.enterText(_campo('Clave'), 'una clave cualquiera');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });

    testWidgets('login correcto entra a "Mis consultas"', (tester) async {
      final repo = repositorioBase();
      when(() => repo.iniciarSesion(any(), any())).thenAnswer((_) async => perfilDemo);
      await montarApp(tester, repo);
      await tester.enterText(_campo('Usuario'), 'maria.perez');
      await tester.enterText(_campo('Clave'), 'una clave cualquiera');
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(ConsultasScreen), findsOneWidget);
      verify(() => repo.iniciarSesion('maria.perez', 'una clave cualquiera')).called(1);
    });

    testWidgets('mostrar/ocultar clave', (tester) async {
      await montarApp(tester, repositorioBase());
      TextField claveCampo() => tester.widget<TextField>(_campo('Clave'));
      expect(claveCampo().obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar clave'));
      await tester.pump();
      expect(claveCampo().obscureText, isFalse);
    });
  });

  group('Registro', () {
    Future<void> abrirRegistro(WidgetTester tester, AuthRepositoryMock repo) async {
      await montarApp(tester, repo);
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.byType(RegistroScreen), findsOneWidget);
    }

    Future<void> llenar(WidgetTester tester, {String clave = 'una frase larga y segura', String? confirmacion}) async {
      await tester.enterText(_campo('Usuario'), 'maria.perez');
      await tester.enterText(_campo('Clave'), clave);
      await tester.enterText(_campo('Repite la clave'), confirmacion ?? clave);
      await tester.enterText(_campo('Código de invitación'), 'CODIGO-FICTICIO');
      await tester.enterText(_campo('Correo (opcional)'), 'maria@ejemplo.edu.ec');
    }

    Future<void> enviar(WidgetTester tester) async {
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets('valida localmente: clave corta y confirmación distinta', (tester) async {
      final repo = repositorioBase();
      await abrirRegistro(tester, repo);
      await llenar(tester, clave: 'corta', confirmacion: 'otra');
      await enviar(tester);
      expect(find.text('Debe tener al menos 12 caracteres.'), findsOneWidget);
      expect(find.text('Las claves no coinciden.'), findsOneWidget);
      verifyNever(
        () => repo.registrar(
          usuario: any(named: 'usuario'),
          clave: any(named: 'clave'),
          codigoInvitacion: any(named: 'codigoInvitacion'),
        ),
      );
    });

    testWidgets('correo ya registrado (409) se muestra en el campo correo', (tester) async {
      final repo = repositorioBase();
      when(
        () => repo.registrar(
          usuario: any(named: 'usuario'),
          clave: any(named: 'clave'),
          codigoInvitacion: any(named: 'codigoInvitacion'),
          correo: any(named: 'correo'),
          nombre: any(named: 'nombre'),
        ),
      ).thenThrow(const ConflictException(detalle: 'El correo ya está registrado.'));
      await abrirRegistro(tester, repo);
      await llenar(tester);
      await enviar(tester);
      final correo = tester.widget<TextField>(_campo('Correo (opcional)'));
      expect(correo.decoration?.errorText, 'El correo ya está registrado.');
    });

    testWidgets('código de invitación inválido (403) se muestra en su campo', (tester) async {
      final repo = repositorioBase();
      when(
        () => repo.registrar(
          usuario: any(named: 'usuario'),
          clave: any(named: 'clave'),
          codigoInvitacion: any(named: 'codigoInvitacion'),
          correo: any(named: 'correo'),
          nombre: any(named: 'nombre'),
        ),
      ).thenThrow(const ForbiddenException(detalle: 'Código de invitación inválido.'));
      await abrirRegistro(tester, repo);
      await llenar(tester);
      await enviar(tester);
      expect(find.text('Código de invitación inválido.'), findsOneWidget);
    });

    testWidgets('registro correcto entra a "Mis consultas" y lo confirma', (tester) async {
      final repo = repositorioBase();
      when(
        () => repo.registrar(
          usuario: any(named: 'usuario'),
          clave: any(named: 'clave'),
          codigoInvitacion: any(named: 'codigoInvitacion'),
          correo: any(named: 'correo'),
          nombre: any(named: 'nombre'),
        ),
      ).thenAnswer((_) async => perfilDemo);
      await abrirRegistro(tester, repo);
      await llenar(tester);
      await enviar(tester);
      expect(find.byType(ConsultasScreen), findsOneWidget);
      expect(find.textContaining('Cuenta creada'), findsOneWidget);
    });
  });

  group('Cierre y expiración de sesión', () {
    testWidgets('cerrar sesión pide confirmación, revoca y vuelve al login', (tester) async {
      final repo = repositorioBase(sesionGuardada: true);
      await montarApp(tester, repo);
      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();
      verify(repo.cerrarSesion).called(1);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('si la sesión expira (refresh rechazado) vuelve al login con aviso', (tester) async {
      final eventos = EventosSesion();
      await montarApp(tester, repositorioBase(sesionGuardada: true), eventos: eventos);
      expect(find.byType(ConsultasScreen), findsOneWidget);
      eventos.notificarExpiracion();
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Tu sesión expiró. Inicia sesión de nuevo.'), findsOneWidget);
    });
  });
}
