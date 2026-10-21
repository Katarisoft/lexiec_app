import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/app/lexiec_app.dart';
import 'package:lexiec/app/routes/app_routes.dart';
import 'package:lexiec/controllers/sesion_controller.dart';
import 'package:lexiec/core/network/eventos_sesion.dart';
import 'package:lexiec/data/models/perfil.dart';
import 'package:lexiec/data/repositories/auth_repository.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:mocktail/mocktail.dart';

class AuthRepositoryMock extends Mock implements AuthRepository {}

class ConversacionesRepositoryMock extends Mock implements ConversacionesRepository {}

final perfilDemo = Perfil(usuario: 'maria.perez', nombre: 'María Pérez', creadoEn: DateTime.utc(2026, 10, 20));

/// Dependencias globales con el repositorio falso (sin almacenamiento seguro ni red).
class BindingPrueba extends Bindings {
  BindingPrueba(this.repositorio, this.eventos, [ConversacionesRepository? conversaciones])
    : conversaciones = conversaciones ?? conversacionesVacias();

  final AuthRepository repositorio;
  final EventosSesion eventos;
  final ConversacionesRepository conversaciones;

  @override
  void dependencies() {
    Get.put<EventosSesion>(eventos);
    Get.put<AuthRepository>(repositorio);
    Get.put<ConversacionesRepository>(conversaciones);
    Get.put<SesionController>(
      SesionController(repositorio: repositorio, eventos: eventos, limpiezas: [conversaciones.limpiarHistorialLocal]),
    );
  }
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
  String ruta = AppRoutes.inicio,
}) async {
  Get.testMode = true;
  await tester.pumpWidget(
    LexiecApp(
      bindingInicial: BindingPrueba(repositorio, eventos ?? EventosSesion(), conversaciones),
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
