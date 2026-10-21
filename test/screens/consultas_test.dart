import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lexiec/core/errors/app_exception.dart';
import 'package:lexiec/data/models/cita.dart';
import 'package:lexiec/data/models/conversacion.dart';
import 'package:lexiec/data/models/mensaje.dart';
import 'package:lexiec/data/repositories/conversaciones_repository.dart';
import 'package:lexiec/screens/consulta/consulta_screen.dart';
import 'package:lexiec/screens/consultas/consultas_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_prueba.dart';

final _ahora = DateTime.now();

Conversacion _conv(String id, String titulo, {int diasAtras = 0}) => Conversacion(
  id: id,
  titulo: titulo,
  creadaEn: _ahora.subtract(Duration(days: diasAtras)),
  actualizadaEn: _ahora.subtract(Duration(days: diasAtras)),
);

final _lista = [
  _conv('1', '¿Qué derechos tienen las personas adultas mayores?'),
  _conv('2', '¿Qué dice el artículo 182 de la Ley de Tránsito?'),
  _conv('3', '¿Qué es la calumnia según el COIP?', diasAtras: 10),
];

ConversacionesRepositoryMock _repo({List<Conversacion>? items, bool desdeCache = false}) {
  final r = conversacionesVacias();
  when(
    r.primeraPagina,
  ).thenAnswer((_) async => PaginaConversaciones(items: items ?? _lista, hayMas: false, desdeCache: desdeCache));
  when(() => r.eliminar(any())).thenAnswer((_) async {});
  return r;
}

Future<void> _abrir(WidgetTester tester, ConversacionesRepositoryMock conversaciones) =>
    montarApp(tester, repositorioBase(sesionGuardada: true), conversaciones: conversaciones);

void main() {
  tearDown(Get.reset);

  testWidgets('lista real agrupada por fecha', (tester) async {
    await _abrir(tester, _repo());
    expect(find.byType(ConsultasScreen), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Anteriores'), findsOneWidget);
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsOneWidget);
  });

  testWidgets('error: muestra el mensaje y "Reintentar" vuelve a cargar', (tester) async {
    final repo = _repo();
    var llamadas = 0;
    when(repo.primeraPagina).thenAnswer((_) async {
      if (llamadas++ == 0) throw const ServerException(statusCode: 500);
      return PaginaConversaciones(items: _lista, hayMas: false);
    });
    await _abrir(tester, repo);
    expect(find.text('Error del servidor. Intenta más tarde.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsOneWidget);
  });

  testWidgets('vacío: la acción "Nueva consulta" crea y abre la consulta', (tester) async {
    final repo = _repo(items: const []);
    final nueva = _conv('n', 'Nueva conversación');
    when(repo.crear).thenAnswer((_) async => nueva);
    when(
      () => repo.detalle('n'),
    ).thenAnswer((_) async => (ConversacionDetalle(conversacion: nueva, mensajes: const []), false));
    await _abrir(tester, repo);
    expect(find.text('Aún no tienes consultas'), findsOneWidget);
    await tester.tap(find.text('Nueva consulta'));
    await tester.pumpAndSettle();
    expect(find.byType(ConsultaScreen), findsOneWidget);
    expect(find.text('¿Qué quieres consultar?'), findsOneWidget); // sugerencias del chat
  });

  testWidgets('sin conexión: muestra el historial guardado con un aviso', (tester) async {
    await _abrir(tester, _repo(desdeCache: true));
    expect(find.text('Sin conexión: estás viendo tu historial guardado.'), findsOneWidget);
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsOneWidget);
  });

  testWidgets('búsqueda sin distinguir tildes', (tester) async {
    await _abrir(tester, _repo());
    await tester.enterText(find.byType(TextField), 'transito');
    await tester.pump();
    expect(find.text('¿Qué dice el artículo 182 de la Ley de Tránsito?'), findsOneWidget);
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsNothing);
  });

  testWidgets('deslizar elimina; "Deshacer" la restaura sin llamar a la API', (tester) async {
    final repo = _repo();
    await _abrir(tester, repo);
    await tester.drag(find.text('¿Qué es la calumnia según el COIP?'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsNothing);
    await tester.tap(find.text('Deshacer'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué es la calumnia según el COIP?'), findsOneWidget);
    verifyNever(() => repo.eliminar(any()));
  });

  testWidgets('sin deshacer, se elimina en el servidor tras unos segundos', (tester) async {
    final repo = _repo();
    await _abrir(tester, repo);
    await tester.drag(find.text('¿Qué es la calumnia según el COIP?'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    verify(() => repo.eliminar('3')).called(1);
  });

  testWidgets('abrir una consulta muestra preguntas, respuesta y el texto literal de la cita', (tester) async {
    final repo = _repo();
    final detalle = ConversacionDetalle(
      conversacion: _lista.first,
      mensajes: [
        Mensaje(id: 1, rol: RolMensaje.usuario, contenido: '¿Desde qué edad se es adulto mayor?', creadoEn: _ahora),
        Mensaje(
          id: 2,
          rol: RolMensaje.asistente,
          contenido: 'Desde los sesenta y cinco años de edad.',
          creadoEn: _ahora,
          citas: const [
            Cita(
              archivo: 'mesicic4_ecu_const.pdf',
              pagina: 18,
              articulo: '36',
              texto:
                  'Se considerarán personas adultas mayores aquellas personas que hayan cumplido los sesenta y cinco años',
            ),
          ],
        ),
      ],
    );
    when(() => repo.detalle('1')).thenAnswer((_) async => (detalle, false));
    await _abrir(tester, repo);
    await tester.tap(find.text('¿Qué derechos tienen las personas adultas mayores?'));
    await tester.pumpAndSettle();
    expect(find.text('Desde los sesenta y cinco años de edad.'), findsOneWidget);
    expect(find.text('mesicic4 ecu const'), findsOneWidget); // documento sobre sus fichas
    await tester.tap(find.text('Art. 36 · pág. 18'));
    await tester.pumpAndSettle();
    expect(find.textContaining('hayan cumplido los sesenta y cinco años'), findsOneWidget);
  });

  testWidgets('consulta eliminada en otro dispositivo (404) muestra un error claro', (tester) async {
    final repo = _repo();
    when(() => repo.detalle('1')).thenThrow(const NotFoundException());
    await _abrir(tester, repo);
    await tester.tap(find.text('¿Qué derechos tienen las personas adultas mayores?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ya no existe'), findsOneWidget);
  });

  testWidgets('eliminar desde el detalle pide confirmación y vuelve a la lista', (tester) async {
    final repo = _repo();
    when(
      () => repo.detalle('2'),
    ).thenAnswer((_) async => (ConversacionDetalle(conversacion: _lista[1], mensajes: const []), false));
    await _abrir(tester, repo);
    await tester.tap(find.text('¿Qué dice el artículo 182 de la Ley de Tránsito?'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Opciones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar consulta'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    verify(() => repo.eliminar('2')).called(1);
    expect(find.byType(ConsultasScreen), findsOneWidget);
    expect(find.text('¿Qué dice el artículo 182 de la Ley de Tránsito?'), findsNothing);
  });

  testWidgets('cerrar sesión vacía el historial local', (tester) async {
    final repo = _repo();
    await _abrir(tester, repo);
    await cerrarSesionDesdeMiCuenta(tester);
    verify(repo.limpiarHistorialLocal).called(1);
  });
}
