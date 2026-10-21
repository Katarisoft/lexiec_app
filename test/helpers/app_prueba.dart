import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/lexiec_app.dart';
import 'package:lexiec/app/routes/app_routes.dart';
import 'package:lexiec/controllers/plan_controller.dart';
import 'package:lexiec/controllers/sesion_controller.dart';
import 'package:lexiec/controllers/tema_controller.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/data/models/perfil.dart';
import 'package:lexiec/data/models/plan.dart';
import 'package:lexiec/data/repositories/auth_repository.dart';
import 'package:lexiec/data/repositories/chat_repository.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:lexiec/data/repositories/documentos_repository.dart';
import 'package:lexiec/data/repositories/planes_repository.dart';
import 'package:lexiec/data/repositories/preferencias_repository.dart';
import 'package:mocktail/mocktail.dart';

class AuthRepositoryMock extends Mock implements AuthRepository {}

class ConversacionesRepositoryMock extends Mock implements ConversacionesRepository {}

class ChatRepositoryMock extends Mock implements ChatRepository {}

class DocumentosRepositoryMock extends Mock implements DocumentosRepository {}

class PreferenciasRepositoryMock extends Mock implements PreferenciasRepository {}

class PlanesRepositoryMock extends Mock implements PlanesRepository {}

final perfilDemo = Perfil(usuario: 'maria.perez', nombre: 'María Pérez', creadoEn: DateTime.utc(2026, 10, 20));

/// Dependencias globales con el repositorio falso (sin almacenamiento seguro ni red).
class BindingPrueba extends Bindings {
  BindingPrueba(
    this.repositorio,
    this.eventos, [
    ConversacionesRepository? conversaciones,
    ChatRepository? chat,
    DocumentosRepository? documentos,
    PreferenciasRepository? preferencias,
    PlanesRepository? planes,
  ]) : conversaciones = conversaciones ?? conversacionesVacias(),
       chat = chat ?? ChatRepositoryMock(),
       documentos = documentos ?? DocumentosRepositoryMock(),
       preferencias = preferencias ?? preferenciasBase(),
       planes = planes ?? planesBase();

  final AuthRepository repositorio;
  final EventosSesion eventos;
  final ConversacionesRepository conversaciones;
  final ChatRepository chat;
  final DocumentosRepository documentos;
  final PreferenciasRepository preferencias;
  final PlanesRepository planes;

  @override
  void dependencies() {
    Get.put<EventosSesion>(eventos);
    Get.put<AuthRepository>(repositorio);
    Get.put<ConversacionesRepository>(conversaciones);
    Get.put<ChatRepository>(chat);
    Get.put<DocumentosRepository>(documentos);
    Get.put<TemaController>(TemaController(preferencias: preferencias));
    final plan = Get.put<PlanController>(PlanController(repositorio: planes));
    Get.put<SesionController>(
      SesionController(
        repositorio: repositorio,
        eventos: eventos,
        limpiezas: [conversaciones.limpiarHistorialLocal, plan.limpiar],
      ),
    );
  }
}

/// Saldo de prueba: plan gratis con 3 de 5 consultas.
final saldoGratis = EstadoPlan(
  modo: ModoPlan.gratis,
  iaRapida: false,
  consultasPagadas: 0,
  gratisLimite: 5,
  gratisRestantes: 3,
  gratisRenuevaEn: DateTime.utc(2026, 11, 1, 5),
);

const catalogoDemo = [
  PlanCatalogo(
    codigo: 'paquete_20',
    nombre: 'Paquete 20',
    consultas: 20,
    dias: 180,
    precioUsd: '4.99',
    descripcion: '20 consultas con IA rápida, válidas 6 meses.',
  ),
];

/// Repositorio de planes falso: plan gratis y un plan a la venta.
PlanesRepositoryMock planesBase({EstadoPlan? saldo}) {
  final r = PlanesRepositoryMock();
  when(r.estado).thenAnswer((_) async => saldo ?? saldoGratis);
  when(r.catalogo).thenAnswer((_) async => catalogoDemo);
  return r;
}

/// Repositorio de conversaciones falso sin consultas (por defecto).
ConversacionesRepositoryMock conversacionesVacias() {
  final r = ConversacionesRepositoryMock();
  when(() => r.prepararPara(any())).thenAnswer((_) async {});
  when(r.historialLocal).thenAnswer((_) async => null);
  when(r.primeraPagina).thenAnswer((_) async => const PaginaConversaciones(items: [], hayMas: false));
  when(r.limpiarHistorialLocal).thenAnswer((_) async {});
  return r;
}

/// Monta la app completa y espera a que la pantalla de inicio decida el destino.
Future<void> montarApp(
  WidgetTester tester,
  AuthRepositoryMock repositorio, {
  EventosSesion? eventos,
  ConversacionesRepository? conversaciones,
  ChatRepository? chat,
  DocumentosRepository? documentos,
  PreferenciasRepository? preferencias,
  PlanesRepository? planes,
  String ruta = AppRoutes.inicio,
}) async {
  Get.testMode = true;
  await tester.pumpWidget(
    LexiecApp(
      bindingInicial: BindingPrueba(
        repositorio,
        eventos ?? EventosSesion(),
        conversaciones,
        chat,
        documentos,
        preferencias,
        planes,
      ),
      rutaInicial: ruta,
    ),
  );
  await tester.pump(const Duration(seconds: 1)); // pausa de la marca en el inicio
  await tester.pumpAndSettle();
}

/// Repositorio falso: bienvenida ya vista y sin sesión guardada (valores por defecto).
AuthRepositoryMock repositorioBase({bool bienvenidaVista = true, bool sesionGuardada = false}) {
  final r = AuthRepositoryMock();
  when(r.bienvenidaVista).thenAnswer((_) async => bienvenidaVista);
  when(r.marcarBienvenidaVista).thenAnswer((_) async {});
  when(r.tieneSesionGuardada).thenAnswer((_) async => sesionGuardada);
  when(r.perfil).thenAnswer((_) async => perfilDemo);
  when(r.cerrarSesion).thenAnswer((_) async {});
  return r;
}

/// Preferencias falsas: tema del sistema.
PreferenciasRepositoryMock preferenciasBase() {
  registerFallbackValue(ThemeMode.system);
  final r = PreferenciasRepositoryMock();
  when(r.tema).thenAnswer((_) async => ThemeMode.system);
  when(() => r.guardarTema(any())).thenAnswer((_) async {});
  return r;
}

/// Desde "Mis consultas", abre "Mi cuenta".
Future<void> abrirMiCuenta(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Mi cuenta'));
  await tester.pumpAndSettle();
}

/// Cierra sesión desde "Mi cuenta" (pide confirmación).
Future<void> cerrarSesionDesdeMiCuenta(WidgetTester tester) async {
  await abrirMiCuenta(tester);
  // OutlinedButton.icon es una subclase privada: se busca por texto, desplazando la lista si hace falta.
  await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200, scrollable: find.byType(Scrollable).first);
  await tester.tap(find.text('Cerrar sesión'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
  await tester.pumpAndSettle();
}
